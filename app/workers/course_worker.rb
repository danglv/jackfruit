class CourseWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :backtrace => true
  sidekiq_options :retry => 1

  def perform(diff, course_id, user_id)
    course = Course.where(id: course_id).first
    user = User.where(id: user_id).first
    owned_course = user.courses.where(:course_id => course.id).first

    lectures_user = []
    course.curriculums.where(type: 'lecture').each do |lecture| 
      lectures_user.push(User::Lecture.new(
          lecture_index: lecture.lecture_index
        )
      )
    end

    owned_course.lectures.each do |lecture_old|
      diff_index = diff.detect{|d| d[0] == lecture_old.lecture_index}

      if !diff_index.blank?
        # get lecture new 
        lecture_new = lectures_user.detect{ |l|
          l.lecture_index == diff_index[1]
        }

        if !lecture_new.blank?
          lecture_new.status = lecture_old.status
          lecture_new.lecture_ratio = lecture_old.lecture_ratio
          lecture_new['course_id'] = lecture_old['course_id']

          if !lecture_old.notes.blank?
            lecture_old.notes.each do |n| 
              note = User::Note.new(:time => n.time, :content => n.content, :lecture_id => lecture_new.id)
              lecture_new.notes.push(note) if note.save
            end         
          end
        end
      end
    end
    owned_course.lectures = []
    owned_course.lectures.push(lectures_user)
    owned_course.save
  end
end