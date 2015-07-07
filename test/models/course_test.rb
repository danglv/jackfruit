require "test_helper"

class CourseTest < ActiveSupport::TestCase
  # def setup
  #   @user = User.new
  # end

  # def teardown
  #   @user = nil
  # end

  # test "not save data" do
  #   assert_not @user.save
  # end

  # test "kind of" do
  #   item = User.first and true
  #   assert_kind_of(User, item)
  # end

  # test "nil user" do
  #   item = User.where(:username.in => ['0898687456543454asdasd']).first and true
  #   assert_nil(item)
  # end


  test "can save course" do
    course = Course.new
    course.name = "test"
    assert course.save
  end
end