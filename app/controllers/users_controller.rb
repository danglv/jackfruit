class UsersController < ApplicationController

  before_filter :authenticate_user

  def index
    learning
  end

  def learning
    learning = Constants::OwnedCourseTypes::LEARNING
    course_ids = @current_user.courses.where(type: learning).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)
  end

  def teaching
    teaching = Constants::OwnedCourseTypes::TEACHING
    course_ids = @current_user.courses.where(type: teaching).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)
  end

  def wishlist
    wishlist = Constants::OwnedCourseTypes::WISHLIST
    course_ids = @current_user.courses.where(type: wishlist).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)
  end

  def search
    keywords = params[:q]
    pattern = /#{Regexp.escape(keywords)}/
    @courses = []
    @current_user.courses.map{|owned_course|
      @courses << owned_course.course if (owned_course.course.name =~ pattern) == 0
    }
  end
end