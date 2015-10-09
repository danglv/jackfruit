class CourseWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :backtrace => true
  sidekiq_options :retry => 1

  def perform(diff, course_id, user_id)
    course_new = Course.where(id: course_id).first
    user = User.where(id: user_id).first
    course_user = user.courses.where(:course_id => course_new.id).first

    lectures_user = []
    course_new.curriculums.where(type: 'lecture').map{|lecture| 
      lectures_user.push(User::Lecture.new(
          lecture_index: lecture.lecture_index
        )
      )
    }

    course_user.lectures.each do |lecture_old|
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
    course_user.lectures = []
    course_user.lectures.push(lectures_user)
    course_user.save
  end
end