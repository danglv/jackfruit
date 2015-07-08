class CoursesController < ApplicationController

  def index
    category_name = params[:category]
    category = Category.where(name: category_name).first

    if category.blank?
      @courses = Course.all
    else
      @courses = Course.where(:category_ids.in => [category.id])
    end
    
    render json: @courses
  end

  def show
    render json: {message: "Not Support Yet"}
  end

  def search
    render json: {message: "Not Support Yet"}
  end
end