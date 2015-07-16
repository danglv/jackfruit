class CoursesController < ApplicationController

  before_filter :validate_content_type_param
  before_filter :authenticate_user, only: [:lecture, :learning]

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

  def list_course
    category_id = params[:category_id]
    page        = params[:page] || 1

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
    sort_by = ORDERING[ordering.to_s] if ORDERING.map(&:first).include?(ordering)

    @courses["all"] = Course.where(condition).order(sort_by).paginate(
      page: page,
      per_page: NUMBER_COURSE_PER_PAGE
    )
  end

  def show
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
    @owned_course = @current_user.courses.where(course_id: course_id).first

    # set lecture ratio = 100(finish)
    @owned_lecture = @owned_course.lectures.where(lecture_index: lecture_index).first
    
    @owned_lecture.set(lecture_ratio: 100, status: 2)
    @current_user.save
  end
  def lecture_exam
  end
  def lecture_detail
  end
  def search
    keywords = params[:q]
    pattern  = /#{Regexp.escape(keywords)}/
    @course  = Course.where(name: pattern).limit(10)

    if @course.count == 0
      @course = Course.where(description: pattern).limit(10)
    end
  end

  def test_course_detail_id

  end

  def detail
    
  end
end