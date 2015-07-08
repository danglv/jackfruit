class CoursesController < ApplicationController

  def index
    category_name = params[:category]
    category = Category.where(name: category_name).first

    if category.blank?
      @courses = Course.all
    else
      @courses = Course.where(:category_ids.in => [category.id])
    end
  end

  def show
    category_name = params[:category]
    @category = Category.where(name: category_name).first
  end

  def search
    keywords = params[:q]
    pattern = /#{Regexp.escape(keywords)}/
    @course = Course.where(name: pattern).limit(10)

    if @course.count == 0
      @course = Course.where(description: pattern).limit(10)
    end
  end
end