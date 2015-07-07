require "test_helper"

class UserTest < ActiveSupport::TestCase
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


  test "can save user" do
    user = User.new
    user.username = "xyz"
    user.name = "test"
    assert user.save
  end
end