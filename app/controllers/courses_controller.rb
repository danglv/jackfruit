class CoursesController < ApplicationController
  include CoursesHelper
  include CodServices

  layout 'courses', except: [:learning, :lecture]

  before_filter :validate_content_type_param, :except => [:suggestion_search]
  before_filter :authenticate_user!, only: [:learning, :lecture, :select, :add_announcement]
  before_filter :validate_course, only: [:detail, :learning, :lecture, :select]
  before_filter :validate_category, only: [:list_course_featured, :list_course_all]
  skip_before_filter :verify_authenticity_token, only: [:upload_course]

  NUMBER_COURSE_PER_PAGE = 10
  ORDERING = {
    "ratings" => {average_rating: -1},
    "newest" => {created_at: -1},
    "price-low-to-high" => {price: 1},
    "price-high-to-low" => {price: -1}
  }

  def index
    labels   = Constants.LabelsValues
    @courses = {}

    labels.each {|label|
      title = if Course::Localization::TITLES[label.to_sym].blank?
        label
      else
        Course::Localization::TITLES[label.to_sym][I18n.default_locale]
      end

      condition = {}
      condition[:enabled] = true
      condition[:label_ids.in] = [label]

      if current_user
        condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
      else
        condition[:version] = Constants::CourseVersions::PUBLIC
      end

      courses_of_label = Course.where(condition).desc(:students).limit(12).to_a

      @courses[label.to_sym] = [title, order_course_of_label(label, courses_of_label)]

      # Get sale info for courses
      @sale_info = help_sale_info_for_course_set @courses
    }
  end

  def list_course_featured
    @category_name = @category.name;
    @courses = {}

    condition = {:enabled => true, :label_ids.in => ["featured"], :category_ids.in => [@category.id]}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    courses_featured = Course.where(condition).desc(:students).limit(4).to_a
    @courses["featured"] = [Course::Localization::TITLES["featured".to_sym][I18n.default_locale], order_course_of_label('featured', courses_featured)]

    condition = {:category_ids.in => [@category.id], :enabled => true}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    courses_top_paid = Course.where(condition).desc(:students).limit(4).to_a
    @courses["top_paid"] = [Course::Localization::TITLES["top_paid".to_sym][I18n.default_locale], order_course_of_label('top_paid', courses_top_paid)]

    condition = {:price => 0,:category_ids.in => [@category.id], :enabled => true}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    courses_top_free = Course.where(condition).desc(:students).limit(4).to_a
    @courses["top_free"] = [Course::Localization::TITLES["top_free".to_sym][I18n.default_locale], order_course_of_label('top_free', courses_top_free)]

    condition = {:price.gt => 0,:category_ids.in => [@category.id], :enabled => true}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    courses_newest = Course.where(condition).desc(:created_at).limit(4).to_a
    @courses["newest"] = [Course::Localization::TITLES["newest".to_sym][I18n.default_locale], order_course_of_label('newest', courses_newest)]

    @other_category = Category.where(
      :parent_category_id => @category.parent_category_id,
      :id.ne => @category_id,
      :enabled => true
      )

    # Get sale info for courses
    @sale_info = help_sale_info_for_course_set @courses
  end

  def list_course_all
    @page = (params[:page] || 1).to_i
    @category_name = @category.name;
    # filter sort paginate course

    budget   = params[:budget]
    lang     = params[:lang]
    level    = params[:level]
    ordering = params[:ordering]
    condition = {}
    condition[:enabled] = true
    condition[:category_ids.in] = [@category.id]

    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

    if budget == Constants::BudgetTypes::FREE
      condition[:price] = 0
    elsif budget == Constants::BudgetTypes::PAID
      condition[:price.gt] = 0
    end

    condition[:lang] = lang if Constants.CourseLangValues.include?(lang)
    condition[:level] = level if Constants.CourseLevelValues.include?(level)

    sort_by = ORDERING.first.last
    sort_by = ORDERING[ordering.to_s] if ORDERING.map(&:first).include?(ordering)

    @courses = Course.where(condition).order(sort_by)
    @total_page = (@courses.count / NUMBER_COURSE_PER_PAGE.to_f).ceil
    @courses = @courses.paginate(
      page: @page,
      per_page: NUMBER_COURSE_PER_PAGE
    )

    @other_category = Category.where(
      :parent_category_id => @category.parent_category_id,
      :id.ne => @category_id,
      :enabled => true
      ).to_a

    # Get sale info for courses
    @sale_info = help_sale_info_for_courses @courses
  end

  def detail
    # If has logged in user then check user's owned course
    if current_user
      # Go to learning with user who has role is reviewer or owned this course
      if current_user.role == "reviewer" || @course.user.id.to_s == current_user.id.to_s
        owned_course = current_user.courses.find_or_create_by(:course_id => @course.id)
        @course.curriculums
        .where(:type => Constants::CurriculumTypes::LECTURE)
        .map{ |curriculum|
          owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
        }
        owned_course.first_learning = false
        owned_course.type = Constants::OwnedCourseTypes::LEARNING
        owned_course.payment_status = Constants::PaymentStatus::SUCCESS
        owned_course.save
      else
        @payment = Payment.where(
          user_id: current_user.id.to_s,
          course_id: @course.id.to_s
        ).last
      end
    end

    # Get Coupon
    begin
      coupon_code = params[:coupon_code]
      @coupon = []
      uri = URI("http://code.pedia.vn/coupon/list_coupon?course_id=all")
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      data['coupons'].each {|coupon|
        if coupon['expired_date'].to_time > Time.now()
          @coupon << coupon
          break
        end
      }
      if !coupon_code.blank?
        if !coupon_code.split(",").blank?
          coupon_code.split(",").each {|coupon|
            uri = URI("http://code.pedia.vn/coupon?coupon=#{coupon}")
            response = Net::HTTP.get(uri)
            coupon = JSON.parse(response)
            if coupon['expired_date'].to_time > Time.now()
              @coupon << coupon
              break
            end
          }
        end
      end
    rescue Exception => e
      @coupon = []
      unless current_user.blank?
        identity = current_user.id.to_s
      else
        identity = Tracking.generate_unique_str
        # Get user owned course
        @owned_course = current_user.courses.where(:course_id => @course.id.to_s).first
        # Check owned course
        if @owned_course # If already has owned course
          # Check course type
          if @owned_course.preview? # If course is preview course
            # Check if course is expired
            if @owned_course.preview_expired? # Expired
              @owned_course = nil # Expired course means has no owned course
              @preview_disabled = true # Could not preview anymore
            else # Available
              redirect_to root_url + "courses/#{@course.alias_name}/learning"
              return
            end
          else # Course is learning course
            # Check course payment status
            if @owned_course.payment_success? # If payment is success then go to learning page
              redirect_to root_url + "courses/#{@course.alias_name}/learning"
              return
            else # Course is on a payment then get payment
              # Tracking L3c. Case pending
              Spymaster.params.cat('L3c').beh('view').tar(@course.id).user(current_user.id).track(request)
              @payment = Payment.where(
                user_id: current_user.id.to_s,
                course_id: @course.id.to_s
              ).to_a.last
            end
          end
        else
          # Tracking L3c. Case not has course.
          Spymaster.params.cat('L3c').beh('view').tar(@course.id).user(current_user.id).track(request)
        end
      end
      Tracking.create_tracking(
          :type => Constants::TrackingTypes::COURSE_DETAILS,
          :content => {
            :message => "die server coupon",
            :status => "fail" },
          :ip => request.remote_ip,
          :platform => {},
          :device => {},
          :version => Constants::AppVersion::VER_1,
          :str_identity => identity,
          :object => @course.id
        )
    end
    # Check if course is in any sale campaign
    sale_input = {:course => @course}
    if !params.blank?
      sale_input[:coupon_code] = params[:coupon_code] unless params[:coupon_code].blank?
    end
    @sale_info = Sale::Services.get_price(sale_input)

    @courses = {}
    # Relative courses
    # condition = {:enabled => true, :category_ids.in => @course.category_ids}
    condition = {:enabled => true}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    # Select three first courses in the same category
    # @courses['related'] = [Course::Localization::TITLES["related".to_sym][I18n.default_locale], Course.where(condition).limit(3)]
    # Select three first courses in relatives list
    rids = @course.relative_ids[0..2]
    rcourses = Course.where(:id.in => rids).where(condition).sort{|a,b| rids.index(a.id) <=> rids.index(b.id)}
    @courses['related'] = [Course::Localization::TITLES["related".to_sym][I18n.default_locale], rcourses]
    # Top paid

    #fixed condition for Oct2015 campaign
    condition = {:enabled => true, :id.in => @course.related}
    @courses['related'] = [
      Course::Localization::TITLES["related".to_sym][I18n.default_locale], Course.where(condition).limit(3)
    ]
    condition = {:enabled => true, :label_ids.in => ["top_paid"]}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    @courses['top_paid'] = [Course::Localization::TITLES["top_paid".to_sym][I18n.default_locale], Course.where(condition).limit(3)]

    # if ["55c3306344616e0ca600001f", "55b1c16f52696418a000001e"].include?(@course.id.to_s)
    #   if params[:layout].to_i == 1
    #     render :template => "courses/detail"
    #     return
    #   else
        
    #     if @course.id.to_s == "55c3306344616e0ca600001f"
    #       @is_experiment_tund = 1
    #     elsif @course.id.to_s == "55cb2d3044616e15ca000000"
    #       @is_experiment_ngocntn = 1
    #     end

    #     render :template => "courses/excel_detail"
    #     return
    #   end
    # elsif ["55b1c17152696418a000005b", "55c312f344616e0ca6000000","55cb2d3044616e15ca000000"].include?(@course.id.to_s)
    #     render :template => "courses/detail_v3"
    #     return
    # else
    #   render :template => "courses/detail"
    #   return
    # end

    if ["55b1c17152696418a000005b", "55c312f344616e0ca6000000","55cb2d3044616e15ca000000"].include?(@course.id.to_s)
      render :template => "courses/detail_v3"
      return
    elsif @course.id.to_s == "55c3306344616e0ca600001f"
      render :template => "courses/detail_combo_promo"
      return
    else
      render :template => "courses/detail"
      return
    end
    @reviews = @course.reviews.where(:title.nin => ["", nil], :description.nin => ["", nil], :user.nin => ["", nil]).limit(5).to_a

    sort_curriculums
    render template: "courses/detail"
  end

  def learning
    # Get owned course: success payment course or preview course
    @owned_course = current_user.courses.where(
      :course_id => @course._id,
    ).or(
      # Preview course
      :type => Constants::OwnedCourseTypes::PREVIEW
    ).or(
      # Learning course
      :payment_status => Constants::PaymentStatus::SUCCESS
    ).first

    # User doesn't have that course
    if @owned_course.blank?
      redirect_to root_url + "courses/#{@course.alias_name}/detail"
      return
    end

    # Check course type
    if @owned_course.preview? # Preview course
      # Check if course is expired
      if @owned_course.preview_expired? # Go to detail if course is expired
        redirect_to root_url + "courses/#{@course.alias_name}/detail"
        return
      end
    else # Other course type (learning...)
      # Check if this is the first time learning
      if @owned_course.first_learning
        @owned_course.set(:first_learning => false)

        # Tracking U8x
        TrackingHelper.track_on_first_learning(current_user, @course, request)

        # Redirect to success payment page if first learning and has payment
        payment = Payment.where(:course_id => @course._id, :user_id => current_user.id, :status => "success").first
        if !payment.blank?
          redirect_to root_url + "home/payment/#{payment.id}/status"
          return
        end
      end
    end

    render layout: 'lecture'
  end

  def lecture
    # Get owned course: success payment course or preview course
    @owned_course = current_user.courses.where(
      :course_id => @course._id,
    ).or(
      # Preview course
      :type => Constants::OwnedCourseTypes::PREVIEW
    ).or(
      # Learning course
      :payment_status => Constants::PaymentStatus::SUCCESS
    ).first

    # User doesn't have that course
    if @owned_course.blank?
      redirect_to root_url + "courses/#{@course.alias_name}/detail"
      return
    end

    # If course is preview course and it's expired
    if @owned_course.preview? && @owned_course.preview_expired?
      redirect_to root_url + "courses/#{@course.alias_name}/detail"
      return
    end

    # Get the lecture of course
    lecture_index = params[:lecture_index]
    @lecture = @course.curriculums.where(:lecture_index => lecture_index, type: "lecture").first

    # Get the owned lecture of the user
    @owned_lecture = @owned_course.lectures.where(lecture_index: lecture_index).first
    # Update lecture status
    @owned_lecture.lecture_ratio = 100 # 100 means finish
    @owned_lecture.status = 2
    @owned_notes = @owned_lecture.notes.to_a
    @owned_course.save

    render layout: 'lecture'
  end

  def search
    @keywords = params[:q]
    @page     = params[:page] || 1
    budget   = params[:budget]
    lang     = params[:lang]
    level    = params[:level]
    ordering = params[:ordering]

    @normalize_keywords = Utils.nomalize_string(@keywords)
    pattern  = /#{Regexp.escape(@normalize_keywords)}/i

    condition = {}

    if budget == Constants::BudgetTypes::FREE
      condition[:price] = 0
    elsif budget == Constants::BudgetTypes::PAID
      condition[:price.gt] = 0
    end

    condition[:enabled] = true
    condition[:lang] = lang if Constants.CourseLangValues.include?(lang)
    condition[:level] = level if Constants.CourseLevelValues.include?(level)
    #condition[:searchable_content] = pattern

    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

    # fix nóng lỗi sv
    condition[:version] = "public"

    @condition = condition
    _query = { "multi_match" => {
        "query" => @keywords,
        "type" => "best_fields",
        "fields" => ["name^5","benefit^2","description^3","sub_title^2","curriculums.title","user.name","user.instructor_profile","user.biography"]
      }
    }
    _must = [
      { "term"=>{
        "enabled" => condition[:enabled] }
      },
      { "term"=>{
        "version" => condition[:version] }
      }
    ]

    if @condition[:lang] != nil
      _must.push({
        "term" => {
          "lang" => @condition[:lang]
        }
      });
    end

    if @condition[:level] != nil
      _must.push({
        "term" => {
          "level" => @condition[:level]
        }
      });
    end

    if budget == Constants::BudgetTypes::FREE
      _must.push({
        "term" => {
          "price" => 0
        }
      });
    end

    if budget == Constants::BudgetTypes::PAID
      _must.push({
        "range" => {
          "price" => {
            "gt" => 10
          }
        }
      });
    end

    body = {
      "query" => {
        "filtered" => {
          "query" => _query,
          "filter" =>
            {
              "and" => _must
            }
        }
      },
      "from" => 0, "size" => 20
    }

    c = Course.search body
    @courses = c.results.map {|r|
      r._source
    } and true

    if @courses.count == 0
      @courses = {}

      condition = {:enabled => true,:label_ids.in => ["featured"]}
      if current_user
        condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
      else
        condition[:version] = Constants::CourseVersions::PUBLIC
      end

      @courses["featured"] = [Course::Localization::TITLES["featured".to_sym][I18n.default_locale], [Course.where(condition).first]]
      condition = {:enabled => true, :price => 0}
      if current_user
        condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
      else
        condition[:version] = Constants::CourseVersions::PUBLIC
      end

      @courses["top_free"] = [Course::Localization::TITLES["top_free".to_sym][I18n.default_locale], Course.where(condition).desc(:students).limit(12)]
      condition = {:enabled => true, :price.gt => 0}
      if current_user
        condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
      else
        condition[:version] = Constants::CourseVersions::PUBLIC
      end

      @courses["top_paid"] = [Course::Localization::TITLES["top_paid".to_sym][I18n.default_locale], Course.where(condition).desc(:students).limit(12)]
      condition = {:enabled => true}
      if current_user
        condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
      else
        condition[:version] = Constants::CourseVersions::PUBLIC
      end

      @courses["newest"] = [Course::Localization::TITLES["newest".to_sym][I18n.default_locale], Course.where(condition).desc(:created_at).limit(12)]
    end
  end

  def select
    labels    = Constants.LabelsValues
    @courses  = {}

    labels.each {|label|
      title = if Course::Localization::TITLES[label.to_sym].blank?
        label
      else
        Course::Localization::TITLES[label.to_sym][I18n.default_locale]
      end

      condition = {:enabled => true, :label_ids.in => [label]}
      if current_user
        condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
      else
        condition[:version] = Constants::CourseVersions::PUBLIC
      end
      @courses[label.to_sym] = [title, Course.where(condition).desc(:students).limit(12)]
    }
  end

  def add_discussion
    course_id = params[:id]
    curriculum_id = params[:curriculum_id]
    parent_discussion = params[:parent_discussion]

    title = params[:title]
    description = params[:description]

    if description.blank?
      render json: {message: "Nội dung không được để trống"}, status: :unprocessable_entity
      return
    end

    @course = Course.where(id: course_id).first
    if @course.blank?
      render json: {message: "Khoá học không tồn tại!"}, status: :unprocessable_entity
      return
    end

    parent_discussion_obj = @course.discussions.where(:id => parent_discussion).first if !parent_discussion.blank?
    discussion = nil

    if parent_discussion_obj.blank?
      discussion = @course.discussions.new(
        title: title,
        description: description
      )
      discussion.course = @course
    else
      discussion = parent_discussion_obj.child_discussions.new(
        description: description
      )
      discussion.parent_discussion = parent_discussion_obj
    end

    discussion.user = current_user
    discussion.curriculum_id = curriculum_id if !curriculum_id.blank?

    if discussion.save
      # send discussion to Wasp through Flow.
      parent_discussion_id = !parent_discussion_obj.blank? ? parent_discussion : discussion.id
      child_discussions = !parent_discussion_obj.blank? ? parent_discussion_obj.child_discussions.as_json : []
      content = (!title.blank?) ? title + ':' + description : description

      # Render json for Pedia
      render json: {
        title: title, 
        description: description, 
        email: current_user.email, 
        avatar: current_user.avatar, 
        name: current_user.name
      }

      if Rails.env != "development"
        RestClient.post("#{FLOW_BASE_API_URL}/wasp/feedback/create",
          course_id: course_id,
          course_name: @course.name,
          user_id: current_user.id.to_s,
          user_name: current_user.name,
          user_email: current_user.email,
          type: "discussion",
          content: content,
          curriculum_id: curriculum_id,
          parent_discussion: parent_discussion_id,
          child_discussions: child_discussions
        )
      end
    else
      render json: {message: discussion.errors}, status: :unprocessable_entity
    end
    # Create varriable to test.
    @discussion = discussion
  end

  def add_discussion_from_wasp
    course_id = params[:id]
    parent_discussion_id = params[:parent_discussion]
    description = params[:description]

    ['id','parent_discussion', 'description'].each do |param|
      if params[param.to_sym].blank?
        render json: {message: "#{param} không được bỏ trống!"}, status: :unprocessable_entity
        return
      end
    end

    user = User.where(:email => "cskh@pedia.vn").first
    course = Course.where(:id => course_id).first

    if course.blank?
      render json: {message: "Khóa học không hợp lệ"}, status: :unprocessable_entity
      return
    end

    parent_discussion = course.discussions.where(:id => parent_discussion_id).first
    if parent_discussion.blank?
      render json: {message: "Parrent discussion không tồn tại"}, status: :unprocessable_entity
      return
    end

    parent_discussion.child_discussions.new(
      created_at: Time.now,
      description: description,
      user_id: user._id
    )
    if !parent_discussion.save
      render json: {error: parent_discussion.errors}, status: :unprocessable_entity
      return
    end
    render json: {message: "success"}
  end

  def edit_discussion
    course_id = params[:id]
    parent_discussion_id = params[:parent_discussion]
    discussion_id = params[:discussion_id]
    description = params[:description]

    ['id','parent_discussion', 'discussion_id', 'description'].each do |param|
      if params[param.to_sym].blank?
        render json: {message: "#{param} không được bỏ trống!"}, status: :unprocessable_entity
        return
      end
    end

    course = Course.where(:id => course_id).first

    if course.blank?
      render json: {message: "Khóa học không hợp lệ"}, status: :unprocessable_entity
      return
    end

    parent_discussion = course.discussions.where(:id => parent_discussion_id).first
    discussion = parent_discussion.child_discussions.where(:id => discussion_id).first if !parent_discussion.blank?

    if discussion.blank?
      render json: {message: "Không tồn tại thảo luận này"}, status: :unprocessable_entity
      return
    else
      discussion.description = description if !description.blank?
      if course.save
        render json: {message: "Sửa thành công"}
      else
        render json: {message: "Không sửa được thảo luận"}, status: :unprocessable_entity
      end
    end
  end

  def delete_discussion
    course_id = params[:id]
    parent_discussion_id = params[:parent_discussion]
    discussion_id = params[:discussion_id]

    ['id','parent_discussion', 'discussion_id'].each do |param|
      if params[param.to_sym].blank?
        render json: {message: "#{param} không được bỏ trống"}, status: :unprocessable_entity
        return
      end
    end

    course = Course.where(:id => course_id).first

    if course.blank?
      render json: {message: "Khóa học không hợp lệ"}, status: :unprocessable_entity
      return
    end

    parent_discussion = course.discussions.where(:discussion_id => parent_discussion_id).first
    discussion = parent_discussion.child_discussions.where(:id => discussion_id).first if !parent_discussion.blank?

    if discussion.blank?
      render json: {message: "Không tồn tại thảo luận này"}, status: :unprocessable_entity
      return
    else
      discussion.delete
      if course.save
        render json: {message: "Xóa thành công"}
      else
        render json: {message: "Không xóa được thảo luận"}, status: :unprocessable_entity
      end
    end
  end

  def rating
    course_id = params[:id]
    title = params[:title]
    description = params[:description]
    rate = params[:rate]

    @course = Course.where(id: course_id).first
    review = @course.reviews.where(:user_id => current_user.id).first

    if @course.blank?
      render json: {message: "Khoá học không hợp lệ!"}, status: :unprocessable_entity
      return
    end

    if review.blank?
      review = @course.reviews.create(
        title: title,
        description: description,
        rate: rate
      )
    else
      review.title = title
      review.description = description
      review.rate = rate
    end
    review.user = current_user
    if @course.save
      render json: {title: title, description: description, email: current_user.email, rate: rate}
      return
    else
      render json: {message: "Có lỗi xảy ra"}
      return
    end
  end

  # GET: API suggestion search for user by name
  def suggestion_search
    keywords = params[:q]
    keywords = Utils.nomalize_string(keywords)
    pattern = /#{Regexp.escape(keywords)}/i

    courses = Course.or({:alias_name => pattern}, {:name => pattern}).map { |course|
      CourseSerializer.new(course).suggestion_search_hash
    }

    render json: courses, root: false
    return
  end

  # GET: API get price of course
  def get_money
    course_id = params[:course_id]
    coupon_code = params[:coupon_code]

    if course_id.blank?
      render json: {message: "chưa truyền dữ course_id"}, status: :unprocessable_entity
      return
    end

    course = Course.find(course_id)

    if course_id.blank?
      render json: {message: "course_id không chính xác"}, status: :unprocessable_entity
    if course.blank?
      render json: {message: "course_id không chính xác"}, status: :unprocessable_entity
      return
    end

    discount = 0
    coupons = []
    if !coupon_code.blank?
      coupon_code.split(",").each {|coupon|
        uri = URI("http://code.pedia.vn/coupon?coupon=#{coupon}")
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)
        if data['return_value'].to_i > 0 && data['expired_date'].to_datetime > Time.now()
          discount += JSON.parse(response)['return_value'].to_f
          coupons << coupon
        end
      }
    end
    price = ((course.price * (100 - discount) / 100) / 1000).to_i * 1000

    render json: {price: "#{price}"}
  end

  # POST: API create course for kelley
  def upload_course
    begin
      course = params['course']
      course_id = params['course_id']
      user_id = params['user_id']

      if user_id.blank?
        render json: {message: "Chưa truyền dữ liệu"}, status: :unprocessable_entity
        return
      else
        user = User.find(user_id)

        if !course_id.blank?
          c = Course.where(:id => course_id).first
        end
        
        c = Course.find_or_initialize_by(
          _id: course_id,
          alias_name: course['alias_name'],
          name: course['name'],
          sub_title: course['sub_title'],
          description: course['description'],
          requirement: course['requirement'],
          benefit: course['benefit'],
          audience: course['audience'],
          level: course['level'],
        ) if c.blank?

        c.alias_name = course['alias_name'] unless course['alias_name'].blank?
        c.price = course['price'] unless course['price'].blank?
        c.image = course['image'] unless course['image'].blank?
        c.intro_link = course['intro_link'] unless course['intro_link'].blank?
        c.intro_image = course['intro_image'] unless course['intro_image'].blank?
        c.enabled = course['enabled'] unless course['enabled'].blank?

        chapter_index = 0
        lecture_index = 0

        if !course['curriculums'].blank?
          course['curriculums'].each_with_index {|curriculum, x|
            course_curriculum = c.curriculums.find_or_initialize_by(
              order: x,
            )
            course_curriculum.title = curriculum['title']
            course_curriculum.description = curriculum['description']
            course_curriculum.chapter_index = chapter_index
            course_curriculum.lecture_index = lecture_index
            course_curriculum.type = curriculum['type']
            course_curriculum.asset_type = curriculum['asset_type']
            course_curriculum.url = curriculum['url']
            course_curriculum.asset_type = "Text" if !Constants.CurriculumAssetTypesValues.include?(curriculum['asset_type'])
            chapter_index += 1 if curriculum['type'] == "chapter"
            lecture_index += 1 if curriculum['type'] == "lecture"
          }
        else
          render json: {message: "Không được bỏ trống curriculum"}, status: :unprocessable_entity
          return
        end
        c.user = user

        if c.save
          render json: c.as_json
          return
        else
          render json: {message: "Lỗi không lưu được data"}, status: :unprocessable_entity
          return
        end
      end
    rescue Exception => e
      render json: {message: e.message}, status: :unprocessable_entity
    end

  end

  # POST: API approve course
  def approve
    course_id = params["id"]

    course = Course.where(id: course_id).first

    if course.blank?
      render json: {message: "Course id Không chính xác!"}, status: :unprocessable_entity
      return
    end

    course.enabled = true
    course.version = "public"

    if course.save
      render json: {message: "Success!"}
      return
    else
      render json: {message: "Lỗi không lưu được dữ liệu!"}, status: :unprocessable_entity
      return
    end
  end

  def check_alias_name
    alias_name = params['alias_name']

    if alias_name.blank?
      render json: {message: "Chưa truyền alias_name"}, status: :unprocessable_entity
      return
    end

    course = Course.where(alias_name: alias_name).count

    render json: {num_courses: course}
  #POST: API UPLOAD Image
  def upload_image
    begin

      file = params[:image]
      file_name = params[:file_name]

      path = Rails.public_path.join("uploads/images/courses/")
      path.mkpath unless path.exist?

      File.open(path.join(file_name), 'wb') do |f|
        f.write(file.read)
      end

      render json: {'image' => "uploads/images/courses/#{file_name}"}
      return

    rescue Exception => e
      render json: {:error => "Có lỗi xảy ra #{e.message}"}
    end
  end

  # API UPLOAD DOCUMENTS FOR KELLEY
  def upload_document
    begin
      file = params[:file]
      file_name = params[:file_name]

      path = Rails.public_path.join("uploads/documents/")
      path.mkpath unless path.exist?

      File.open(path.join(file_name), 'wb') do |f|
        f.write(file.read)
      end

      render json: {'document' => "uploads/documents/#{file_name}"}
      return
    rescue Exception => e
      render json: {:error => "Có lỗi xảy ra #{e.message}"}
    end
  end

  def add_announcement
    course_id = params[:id]
    title = params[:title]
    description = params[:description]

    if description.blank?
      render json: {error: 'Description không được bỏ trống!'}, status: :unprocessable_entity
      return
    end

    course = Course.where(:id => course_id).first
    if course.blank?
      render json: {error: 'Khoá học không tồn tại!'}, status: :unprocessable_entity
      return
    end

    if course.user.id != current_user.id
      render json: {error: 'Tài khoản đang đăng nhập không sở hữu khoá học này!'}, status: :unprocessable_entity
      return
    end

    announcement = course.announcements.new(
      title: title,
      description: description,
      user_id: current_user.id
    )

    if !announcement.save
      render json: {error: announcement.errors}, status: :unprocessable_entity
      return
    end

    render json: {
      title: title,
      description: description,
      email: current_user.email,
      avatar: current_user.avatar,
      name: current_user.name
    }
  end

  def add_child_announcement
    description = params[:description]
    parent_announcement_id = params[:parent_announcement_id]
    course_id = params[:id]

    if description.blank?
      render json: {error: 'Description không được bỏ trống!'}, status: :unprocessable_entity
      return
    end

    if parent_announcement_id.blank?
      render json: {error: 'parent_announcement_id không được bỏ trống!'}, status: :unprocessable_entity
      return
    end

    course = Course.where(:id => course_id).first
    if course.blank?
      render json: {error: 'Khoá học không tồn tại!'}, status: :unprocessable_entity
      return
    end

    parent_announcement = course.announcements.where(:id => parent_announcement_id).first
    if parent_announcement.blank?
      render json: {error: 'Thông báo không tồn tại!'}, status: :unprocessable_entity
      return
    end

    @child_announcement = parent_announcement.child_announcements.new(
      description: description,
      user_id: current_user.id
    )

    if !@child_announcement.save
      render json: {error: @child_announcement.errors}
      return
    end

    render json: {
      description: description,
      email: current_user.email,
      avatar: current_user.avatar,
      name: current_user.name
    }

    # render plain: '<div class="row child-item no-margin"><div class="col-md-1 col-lg-1 no-padding child-item-avatar"><i class="fa fa-smile-o"></i></div><div class="col-md-11 col-lg-11 no-padding child-item-main"><ul class="child-item-title"><li class="bold">'+current_user.name+'</li><li>'+TimeHelper.relative_time(child_announcement.created_at)+'</li></ul><p class="child-item-content">'+description+'</p></div></div>'
  end

  def send_form_suppot_detail

    uri = URI('http://flow.pedia.vn:8000/notify/course_page_support/create')
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(params)
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
    else
      res.value
    end

    head :ok
  end

  # Activate a course by a code
  # A hack method
  # GET, POST
  def activate
    if request.method == 'POST'
      result = check_activation_code(params['activation_code'])
      unless result[0]
        @error = 'Mã kích hoạt không hợp lệ, vui lòng thử lại'
      else
        @data = { 'step' => 2 }
        cookies[:activation_code] = params['activation_code']
      end
    elsif request.method == 'GET'
      if cookies[:activation_code] && user_signed_in?
        result = check_activation_code(cookies[:activation_code])
        cod = result[1]
        res = create_payment(cod, current_user)

        if res
          @data = { 'step' => 3, 'payment' => res[0], 'course' => res[1], 'author' => res[2] }
          cookies.delete 'activation_code'
        else
          
        end
      end
    end
  end
end