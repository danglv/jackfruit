class CoursesController < ActionController::Base

  def index
    # render json: {message: "Not Support Yet"}
    @courses = Course.all
    @a = 1;
  end

  def show
    render json: {message: "Not Support Yet"}
  end

  def search
    render json: {message: "Not Support Yet"}
  end
end