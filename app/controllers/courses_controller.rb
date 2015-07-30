class CoursesController < ApplicationController
  before_filter :validate_content_type_param
  before_filter :authenticate_user!, only: [:learning, :lecture, :select, :add_discussion]

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

      @courses[label.to_sym] = [title, Course.where(:label_ids.in => [label]).limit(12)]
    }
  end

  def list_course_featured
    @category_id = params[:category_id]
    category = Category.where(id: @category_id).first

    if category.blank?
      redirect_to root_url + "courses"
      return
    end

    @category_name = category.name;

    @courses = {}
    @courses["featured"] = [Course::Localization::TITLES["featured".to_sym][I18n.default_locale], Course.where(
      :label_ids.in => ["featured"],
      :category_ids.in => [category.id]).first]

    @courses["top_free"] = [Course::Localization::TITLES["top_free".to_sym][I18n.default_locale], Course.where(
      :price => 0,
      :category_ids.in => [category.id]
    ).desc(:students).limit(12)]

    @courses["top_paid"] = [Course::Localization::TITLES["top_paid".to_sym][I18n.default_locale], Course.where(
      :price.gt => 0,
      :category_ids.in => [category.id]
    ).desc(:students).limit(12)]

    @courses["newest"] = [Course::Localization::TITLES["newest".to_sym][I18n.default_locale], Course.where(
      :category_ids.in => [category.id],
    ).desc(:created_at).limit(12)]

    @other_category = Category.where(
      :parent_category_id => category.parent_category_id,
      :id.ne => @category_id
      )
  end

  def list_course_all
    @category_id = params[:category_id]
    @page        = params[:page] || 1

    category = Category.where(id: @category_id).first

    if category.blank?
      redirect_to root_url + "courses"
      return
    end

    @category_name = category.name;
    # filter sort paginate course

    budget   = params[:budget]
    lang     = params[:lang]
    level    = params[:level]
    ordering = params[:ordering]
    condition = {}
    condition[:category_ids.in] = [category.id]

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
      :parent_category_id => category.parent_category_id,
      :id.ne => @category_id,
      :enabled => true
      )
  end

  def detail
    course_alias_name = params[:alias_name]
    @course = Course.where(alias_name: course_alias_name).first

    if @course.blank?
      redirect_to root_url + "courses"
      return
    end

    if current_user
      if !current_user.courses.where(:course_id => @course.id.to_s).first.blank?
        redirect_to root_url + "courses/#{course_alias_name}/learning"
        return
      end
    end

    @courses = {}
    
    @courses['related'] = [Course::Localization::TITLES["related".to_sym][I18n.default_locale], Course.where(:category_ids.in => @course.category_ids).limit(3)]
    @courses['top_paid'] = [Course::Localization::TITLES["top_paid".to_sym][I18n.default_locale], Course.where(:category_ids.in => @course.category_ids).limit(3)]
  end

  def learning
    course_alias_name = params[:alias_name]
    @course = Course.where(alias_name: course_alias_name).first

    if @course.blank?
      redirect_to root_url + "courses"
      return
    end

    @owned_course = current_user.courses.where(course_id: @course._id).first
    if @owned_course.blank?
      redirect_to root_url + "courses/#{course_alias_name}/detail"
      return
    end
  end

  def lecture 
    course_alias_name     = params[:alias_name]
    lecture_index = params[:lecture_index]
    @course       = Course.where(alias_name: course_alias_name).first

    if @course.blank?
      redirect_to root_url + "courses"
      return
    end

    @lecture = @course.curriculums.where(:lecture_index => lecture_index, type: "lecture").first
    @owned_course = current_user.courses.where(course_id: @course._id).first
    
    if @owned_course.blank?
      redirect_to root_url + "courses/#{course_id}/detail"
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
    pattern  = /#{Regexp.escape(@keywords)}/i

    condition = {}

    if budget == Constants::BudgetTypes::FREE
      condition[:price] = 0
    elsif budget == Constants::BudgetTypes::PAID
      condition[:price.gt] = 0
    end

    condition[:lang] = lang if Constants.CourseLangValues.include?(lang)
    condition[:level] = level if Constants.CourseLevelValues.include?(level)
    condition[:name] = pattern

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
      
      @courses["featured"] = [Course::Localization::TITLES["featured".to_sym][I18n.default_locale], [Course.where(
      :label_ids.in => ["featured"]).first]]

      @courses["top_free"] = [Course::Localization::TITLES["top_free".to_sym][I18n.default_locale], Course.where(
        :price => 0).desc(:students).limit(12)]

      @courses["top_paid"] = [Course::Localization::TITLES["top_paid".to_sym][I18n.default_locale], Course.where(
        :price.gt => 0
      ).desc(:students).limit(12)]

      @courses["newest"] = [Course::Localization::TITLES["newest".to_sym][I18n.default_locale], Course.all.desc(:created_at).limit(12)]
    end
  end

  def select
    course_alias_name = params[:alias_name]
    @course   = Course.where(alias_name: course_alias_name).first

    if @course.blank?
      redirect_to root_url + "courses"
      return
    end

    labels    = Constants.LabelsValues
    @courses  = {}
  
    labels.each {|label|
    title = if Course::Localization::TITLES[label.to_sym].blank?
      label
    else
      Course::Localization::TITLES[label.to_sym][I18n.default_locale]
    end

    @courses[label.to_sym] = [title, Course.where(:label_ids.in => [label]).limit(12)]
   }
  end

  def add_discussion
    course_id     = params[:id]
    curriculum_id = params[:curriculum_id]
    title         = params[:title]
    description   = params[:description]
    @course       = Course.where(id: course_id).first

    if @course.blank?
      render json: {message: "Khoá học không hợp lệ!"}, status: :unprocessable_entity
      return
    end

    curriculum    = @course.curriculums.where(id:curriculum_id).first

    discussion = @course.discussions.create(
      title: title,
      description: description,
    )
    discussion.user = current_user
    discussion.curriculum = curriculum if !curriculum.blank?
    if @course.save
      render json: {title: title, description: description, email: current_user.email}
      return
    else
      render json: {message: "Có lỗi xảy ra"}
      return
    end
  end
end