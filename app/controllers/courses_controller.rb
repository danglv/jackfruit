class CoursesController < ApplicationController
  include CoursesHelper

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
    end
    # Check if course is in any sale campaign
    sale_input = {:course => @course}
    if !params.blank?
      sale_input[:coupon_code] = params[:coupon_code] unless params[:coupon_code].blank?
    end
    @sale_info = Sale::Services.get_price(sale_input)

    @courses = {}
    condition = {:enabled => true, :category_ids.in => @course.category_ids}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

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
        if @course.free? # Free course
          if current_user.courses.count == 1
            # Tracking U8f: User has the first course is free course
            Spymaster.params.cat('U8f').beh('click').tar(@course.id).user(current_user.id).track(request)
          elsif Course.where(:id.in => current_user.courses.map(&:course_id), :price => 0).count == 1
            # Tracking U8pf: User had a paid course before and now has a new free course
            Spymaster.params.cat('U8pf').beh('click').tar(@course.id).user(current_user.id).track(request)
          end
        else # Paid course
          if current_user.courses.count == 1
            # Tracking U8p: User has the first course is paid course
            Spymaster.params.cat('U8p').beh('click').tar(@course.id).user(current_user.id).track(request)
          elsif Course.where(:id.in => current_user.courses.map(&:course_id), :price.gt => 0).count == 1
            # Tracking U8fp: User had a free course before and now has a new paid course
            Spymaster.params.cat('U8fp').beh('click').tar(@course.id).user(current_user.id).track(request)
          end
        end

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
    title = params[:title]
    description = params[:description]
    parent_discussion = params[:parent_discussion]

    if description.blank?
      render json: {message: "Nội dung không được để trống"}, status: :unprocessable_entity
    end

    @course = Course.where(id: course_id).first
    if @course.blank?
      render json: {message: "Khoá học không hợp lệ!"}, status: :unprocessable_entity
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
      discussion.parent_discussion = parent_discussion_obj if !parent_discussion_obj.blank?
    end

    discussion.user = current_user
    discussion.curriculum_id = curriculum_id if !curriculum_id.blank?

    if discussion.save
      parent_discussion_id = !parent_discussion_obj.blank? ? parent_discussion : discussion.id
      child_discussions = !parent_discussion_obj.blank? ? parent_discussion_obj.child_discussions.as_json : []
      content = (!title.blank?) ? title + ':' + description : description
      # send discussion to Flow
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

      render json: {title: title, description: description, email: current_user.email, avatar: current_user.avatar, name: current_user.name}
      return
    else
      render json: {message: "Có lỗi xảy ra"}
      return
    end
  end

  def edit_discussion
    discussion_id = params[:discussion_id]
    description = params[:description]

    if !discussion_id.blank?
      @discussion = Discussion.where(id: discussion_id).first
      @discussion.description = description

      if @discussion.save
        render json: {massage: "Sửa thảo luận thành công"}
        return
      else
        render json: {message: "Có lỗi xảy ra"}
        return
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
    course_id = params[:course_id]
    title = params[:title]
    description = params[:description]

    @course = Course.where(:id => course_id).first
    announcement = Course::Announcement.new(
      title: title,
      description: description,
      user: @current_user,
      course: @course
      )
    @course.announcements << announcement
    @course.save
    render json: {message: "success"}
    return
  end

  def add_child_announcement
    description = params[:description]
    parent_announcement_id = params[:parent_announcement_id]
    course_id = params[:course_id]

    @course = Course.where(:id => course_id).first
    parent_announcement = @course.announcements.where(:id => parent_announcement_id).first

    child_announcement = Course::ChildAnnouncement.new(
      description: description,
      user: @current_user
      )
    parent_announcement.child_announcements << child_announcement
    @course.save
    if @course.save
      render plain: '<div class="row child-item no-margin"><div class="col-md-1 col-lg-1 no-padding child-item-avatar"><i class="fa fa-smile-o"></i></div><div class="col-md-11 col-lg-11 no-padding child-item-main"><ul class="child-item-title"><li class="bold">'+@current_user.name+'</li><li>'+TimeHelper.relative_time(child_announcement.created_at)+'</li></ul><p class="child-item-content">'+description+'</p></div></div>'
    else
      render json: {message: "false"}
    end

    return
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

  private
    def diff(lectures_old, lectures_new)
      old_lectures_hash = lectures_old.to_h
      new_lecture_hash = lectures_new.to_h

      lectures_diff = old_lectures_hash.keys & new_lecture_hash.keys
      lectures_index_old = lectures_diff.map{ |diff| old_lectures_hash[diff]}
      lectures_index_new = lectures_diff.map{ |diff| new_lecture_hash[diff]}

      if lectures_new.length == lectures_old.length && lectures_index_old == lectures_index_new
        return []
      end
      return lectures_index_old.zip(lectures_index_new)
    end
end