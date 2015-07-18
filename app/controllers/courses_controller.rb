class CoursesController < ApplicationController
  before_filter :validate_content_type_param, :list_category
  before_filter :authenticate_user!, only: [:learning, :lecture, :select]

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
      @courses[label.to_sym] = Course.where(:label_ids.in => [label]).limit(12)
    }
  end

  def list_course_featured
    category_id = params[:category_id]
    category = Category.where(id: category_id).first

    @courses = {}
    @courses["featured"] = Course.where(
      :label_ids.in => ["featured"],
      :category_ids.in => [category.id]).first

    @courses["top_free"] = Course.where(
      :price => 0,
      :category_ids.in => [category.id]
    ).desc(:students).limit(12)

    @courses["top_paid"] = Course.where(
      :price.gt => 0,
      :category_ids.in => [category.id]
    ).desc(:students).limit(12)

    @courses["newest"] = Course.where(
      :category_ids.in => [category.id],
    ).desc(:created_at).limit(12)

    @other_category = Category.where(
      :parent_category_id => category.parent_category_id,
      :id.ne => category_id
      )
  end

  def list_course_all
    category_id = params[:category_id]
    page        = params[:page] || 1

    category = Category.where(id: category_id).first
    # filter sort paginate course

    budget   = params[:budget]
    lang     = params[:lang]
    level    = params[:level]
    ordering = params[:ordering]
    condition = {}
    condition[:category_ids.in] = [category.id]

    if budget == Constants::BudgetTypes::FREE
      condition[:price] = 0
    else
      condition[:price.gt] = 0
    end

    condition[:lang] = lang if Constants.CourseLangValues.include?(lang)
    condition[:level] = level if Constants.CourseLevelValues.include?(level)

    sort_by = ORDERING.first.last
    sort_by = ORDERING[ordering.to_s] if ORDERING.map(&:first).include?(ordering)

    @courses = Course.where(condition).order(sort_by)

    @total_page = (@courses.count / NUMBER_COURSE_PER_PAGE.to_f).ceil
    @courses = @courses.paginate(
      page: page,
      per_page: NUMBER_COURSE_PER_PAGE
    )

    @other_category = Category.where(
      :parent_category_id => category.parent_category_id,
      :id.ne => category_id
      )
  end

  def detail
    course_id = params[:id]
    @course = Course.where(id: course_id).first
  end

  def learning
    course_id = params[:id]
    @course = Course.where(id: course_id).first
  end

  def lecture 
    course_id     = params[:id]
    lecture_index = params[:lecture_index]
    @course       = Course.where(id: course_id).first

    if @course.blank?
      render json: {message: "khóa học không hợp lệ!"}
    end

    @lecture = @course.curriculums.where(:lecture_index => lecture_index).first
    @owned_course = current_user.courses.where(course_id: course_id).first

    # set lecture ratio = 100(finish)
    @owned_lecture = @owned_course.lectures.where(lecture_index: lecture_index).first
    
    @owned_lecture.set(lecture_ratio: 100, status: 2)
    current_user.save
  end

  def lecture_exam
  end

  def lecture_detail
  end

  def search
    @keywords = params[:q]
    page     = params[:page] || 1
    budget   = params[:budget]
    lang     = params[:lang]
    level    = params[:level]
    ordering = params[:ordering]
    pattern  = /#{Regexp.escape(@keywords)}/

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

    @course  = Course.where(condition).order(sort_by)
    
    if @course.count == 0
      condition.delete(:name)
      condition[:description] = pattern  
      @course  = Course.where(condition).order(sort_by)
    end

    @course = @course.paginate(page: page, per_page: NUMBER_COURSE_PER_PAGE)

    if @course.count == 0
      @courses = {}
      @courses["featured"] = Course.where(
        :label_ids.in => ["featured"]).first

      @courses["top_free"] = Course.where(
        :price => 0
      ).desc(:students).limit(12)

      @courses["top_paid"] = Course.where(
        :price.gt => 0
      ).desc(:students).limit(12)

      @courses["newest"] = Course.all.desc(:created_at).limit(12)
    end
  end

  def test_course_detail_id

  end

  def select
    course_id = params[:id]
    @course   = Course.where(id: course_id).first
    
    labels    = Constants.LabelsValues
    @courses  = {}
    
    labels.each {|label|
      @courses[label.to_sym] = Course.where(:label_ids.in => [label]).limit(12)
    }
  end
end