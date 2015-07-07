class CoursesController < ActionController::Base

  def index
    # render json: {message: "Not Support Yet"}
    @courses = Course.all
    @a = 1;
  end

  def list
    render json: {message: "Not Support Yet"}
  end

  def course_detail
    render json: {message: "Not Support Yet"}
  end

  def owned_course
    render json: {message: "Not Support Yet"}
  end
end