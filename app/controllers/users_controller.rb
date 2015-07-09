class UsersController < ApplicationController

  before_filter :authenticate_user

  def index
    learning
  end

  def learning
    learning = Constants::OwnedCourseTypes::LEARNING
    course_ids = @current_user.courses.where(type: learning).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

    head :ok
  end

  def teaching
    teaching = Constants::OwnedCourseTypes::TEACHING
    course_ids = @current_user.courses.where(type: teaching).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

    head :ok
  end

  def wishlist
    wishlist = Constants::OwnedCourseTypes::WISHLIST
    course_ids = @current_user.courses.where(type: wishlist).map(&:course_id)
    @courses = Course.where(:id.in => course_ids)

    head :ok
  end

  def search
    keywords = params[:q]
    pattern = /#{Regexp.escape(keywords)}/
    @courses = []
    @current_user.courses.map{|owned_course|
      @courses << owned_course.course if (owned_course.course.name =~ pattern) == 0
    }

    head :ok
  end

  def select_course
    course_id = params[:course_id]
    owned_course = @current_user.courses.create(
      type: Constants::OwnedCourseTypes::LEARNING,
      course_id: course_id
    )
    init_lectures_for_owned_course(owned_course, course_id)
    @current_user.save

    head :ok
  end

  private
    def init_lectures_for_owned_course(owned_course, course_id)
      course = Course.where(id:course_id).first
      course.curriculums.where(
        :type => Constants::CurriculumTypes::LECTURE
      ).map{|lecture|
        owned_course.lectures.create(:curriculum_id => lecture.id)
      }
    end
end