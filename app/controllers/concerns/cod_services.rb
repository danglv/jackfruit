module CodServices extend ActiveSupport::Concern
  def check_activation_code(activation_code)
    response = RestClient.get('http://code.pedia.vn/cod/detail', {
      params: {
        cod: activation_code
      }, 
      accept: :json
    }) { |response, request, result, &block|
      data = JSON.parse(response)
      case result.code
      when "200"
        return true, data
      else
        return false, data['message']
      end
    }
  end

  def create_payment(cod_data, user)
    course = Course.find(cod_data['course_id'])

    payment = Payment.new(
      :user_id => user.id.to_s,
      :course_id => course.id.to_s,
      :name => user.name,
      :email => user.email,
      :status => Constants::PaymentStatus::SUCCESS,
      :money => cod_data['price'],
      :cod_code => cod_data['cod']
    )

    owned_course = user.courses.find_or_initialize_by(course_id: course.id.to_s)
    owned_course.created_at = Time.now() if owned_course.created_at.blank?

    # Create lecture for user
    course.curriculums.where(
      :type => Constants::CurriculumTypes::LECTURE
    ).map{ |curriculum|
      owned_course.lectures.find_or_initialize_by(:lecture_index => curriculum.lecture_index)
    }

    course.students += 1

    owned_course.type = Constants::OwnedCourseTypes::LEARNING
    owned_course.payment_status = Constants::PaymentStatus::SUCCESS
    owned_course.first_learning = false

    if (payment.save && user.save && course.save)
      return [payment, course, course.user]
    else
      return false
    end
  end
end