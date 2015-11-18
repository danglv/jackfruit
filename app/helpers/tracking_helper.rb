module TrackingHelper

  def self.track_on_first_learning(user, course, request = nil)
    # Tracking U8x
    if course.free? # Free course
      if user.courses.count == 1
        # Tracking U8f: User has the first course is free course
        Spymaster.params.cat('U8f').beh('click').tar(course.id).user(user.id).track(request)
      elsif Course.where(:id.in => user.courses.map(&:course_id), :price => 0).count == 1
        # Tracking U8pf: User had a paid course before and now has a new free course
        Spymaster.params.cat('U8pf').beh('click').tar(course.id).user(user.id).track(request)
      end
    else # Paid course
      if user.courses.count == 1
        # Tracking U8p: User has the first course is paid course
        Spymaster.params.cat('U8p').beh('click').tar(course.id).user(user.id).track(request)
      elsif Course.where(:id.in => user.courses.map(&:course_id), :price.gt => 0).count == 1
        # Tracking U8fp: User had a free course before and now has a new paid course
        Spymaster.params.cat('U8fp').beh('click').tar(course.id).user(user.id).track(request)
      end
    end
  end
end