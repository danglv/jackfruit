require 'test_helper'

class Contactc3Test < ActiveSupport::TestCase
  
  def setup
    @contact_data = {
      :course_id => "123456789abcdef",
      :course_name => 'This is a course name',
      :name => 'A test user',
      :mobile => '0123456789',
      :email => 'An unique email',
      :type => 'An unique type',
      :msg => 'An unique detail',
      :status => Contactc3::Status::IMPORTED
    } 
  end

  def teardown
    Contactc3.delete_all
  end

  test 'must save status' do
    contact = Contactc3.new(@contact_data)
    assert contact.save
    assert_equal Contactc3::Status::IMPORTED, @contact_data[:status]
  end

  test 'must auto save status' do
    @contact_data.delete(:status)
    contact = Contactc3.new(@contact_data)
    assert contact.save
    assert_equal Contactc3::Status::IMPORTED, contact.status
  end

  test 'must not save invalid status' do
    @contact_data[:status] = 'An invalid status'
    contact = Contactc3.new(@contact_data)
    assert_not contact.save
    assert contact.errors.messages.has_key?(:status)
  end
end

