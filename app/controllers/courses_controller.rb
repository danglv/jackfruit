class CoursesController < ApplicationController
  before_filter :validate_content_type_param, :except => [:suggestion_search]
  before_filter :authenticate_user!, only: [:learning, :lecture, :select, :add_discussion]
  before_filter :validate_course, only: [:detail, :learning, :lecture, :select]
  before_filter :validate_category, only: [:list_course_featured, :list_course_all] 

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

      @courses[label.to_sym] = [title, Course.where(condition).desc(:students).limit(12).to_a]
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
    @courses["featured"] = [Course::Localization::TITLES["featured".to_sym][I18n.default_locale], Course.where(condition).limit(4)]

    condition = {:category_ids.in => [@category.id], :enabled => true}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    @courses["top_paid"] = [Course::Localization::TITLES["top_paid".to_sym][I18n.default_locale], Course.where(condition).desc(:students).limit(4)]

    condition = {:price => 0,:category_ids.in => [@category.id], :enabled => true}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    @courses["top_free"] = [Course::Localization::TITLES["top_free".to_sym][I18n.default_locale], Course.where(condition).desc(:students).limit(4)]

    condition = {:price.gt => 0,:category_ids.in => [@category.id], :enabled => true}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end
    @courses["newest"] = [Course::Localization::TITLES["newest".to_sym][I18n.default_locale], Course.where(condition).desc(:created_at).limit(4)]

    @other_category = Category.where(
      :parent_category_id => @category.parent_category_id,
      :id.ne => @category_id,
      :enabled => true
      )
  end

  def list_course_all
    @page        = params[:page] || 1
    @page = @page.to_i
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
      )
  end

  def detail
    if current_user
      @owned_course = current_user.courses.where(:course_id => @course.id.to_s).first
      if @owned_course
        # Course is learnable
        if @owned_course.payment_status == Constants::PaymentStatus::SUCCESS
          # Expired preview course
          if @owned_course.preview? && @owned_course.preview_expired?
            @owned_course = nil
            @preview_disabled = true
          # Learning course
          else
            redirect_to root_url + "courses/#{@course.alias_name}/learning"
            return
          end
        # Course is on payment
        else
          @payment = Payment.where(
            user_id: current_user.id.to_s,
            course_id: @course.id.to_s
          ).last
        end
      end

    end

    # Check if course is in any sale campaign
    sale_input = {:course => @course}
    sale_input[:coupon_code] = params[:coupon_code] unless params[:coupon_code].blank?
    @sale_info = Sale::Services.get_price(sale_input)

    @courses = {}
    condition = {:enabled => true, :category_ids.in => @course.category_ids}
    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

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

    render :template => "courses/detail"
  end

  def learning
    @owned_course = current_user.courses.where(
      :course_id => @course._id,
      :payment_status => Constants::PaymentStatus::SUCCESS
    ).first

    payment = Payment.where(:course_id => @course._id, :user_id => current_user.id, :status => "success").first

    if @owned_course && @owned_course.preview? && @owned_course.preview_expired?
      redirect_to root_url + "courses/#{@course.alias_name}/detail"
      return
    end

    if @owned_course.blank?
      redirect_to root_url + "courses/#{@course.alias_name}/detail"
      return
    end
    # Redirect to success payment page if first learning and have payment
    if (@owned_course.first_learning && !payment.blank?)
      redirect_to root_url + "home/payment/#{payment.id}/success?p=#{payment.method}"
      return
    end

    # Update first learning if free course.
    if @owned_course.first_learning == true
      @owned_course.set(:first_learning => false)
    end
  end

  def lecture 
    lecture_index = params[:lecture_index]
    @lecture = @course.curriculums.where(:lecture_index => lecture_index, type: "lecture").first
    @owned_course = current_user.courses.where(
      :course_id => @course._id,
      :payment_status => Constants::PaymentStatus::SUCCESS
    ).first
    if @owned_course && @owned_course.preview? && @owned_course.preview_expired?
      redirect_to root_url + "courses/#{@course.alias_name}/detail"
      return
    end
    if @owned_course.blank?
      redirect_to root_url + "courses/#{@course.alias_name}/detail"
      return
    end
    
    # set lecture ratio = 100(finish)
    @owned_lecture = @owned_course.lectures.where(lecture_index: lecture_index).first
    
    @owned_lecture.lecture_ratio = 100
    @owned_lecture.status = 2
    @owned_course.save
    current_user.save
  end

  def search
    @keywords = params[:q]
    @page     = params[:page] || 1
    budget   = params[:budget]
    lang     = params[:lang]
    level    = params[:level]
    ordering = params[:ordering]

    @keywords = Utils.nomalize_string(@keywords)
    pattern  = /#{Regexp.escape(@keywords)}/i

    condition = {}

    if budget == Constants::BudgetTypes::FREE
      condition[:price] = 0
    elsif budget == Constants::BudgetTypes::PAID
      condition[:price.gt] = 0
    end

    condition[:enabled] = true
    condition[:lang] = lang if Constants.CourseLangValues.include?(lang)
    condition[:level] = level if Constants.CourseLevelValues.include?(level)
    condition[:alias_name] = pattern

    if current_user
      condition[:version] = Constants::CourseVersions::PUBLIC if current_user.role == "user"
    else
      condition[:version] = Constants::CourseVersions::PUBLIC
    end

    sort_by = ORDERING.first.last    
    sort_by = ORDERING[ordering.to_s] if ORDERING.map(&:first).include?(ordering)

    @courses  = Course.where(condition).order(sort_by)
    @total_page = (@courses.count.to_f / NUMBER_COURSE_PER_PAGE.to_f).ceil;

    if @courses.count == 0
      condition.delete(:name)
      condition[:description] = pattern  
      @courses  = Course.where(condition).order(sort_by)
    end

    @courses = @courses.paginate(page: @page, per_page: NUMBER_COURSE_PER_PAGE)

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
      render json: {title: title, description: description, email: current_user.email, avatar: current_user.avatar, name: current_user.name}
      return
    else
      render json: {message: "Có lỗi xảy ra"}
      return
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

    if keywords.blank?
      render json: {}
      return
    end

    keywords = Utils.nomalize_string(keywords)
    pattern = /#{Regexp.escape(keywords)}/

    courses = Course.where(:alias_name => pattern).map { |course|
      CourseSerializer.new(course).suggestion_search_hash
    }

    render json: courses, root: false
    return
  end

end