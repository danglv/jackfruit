# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Data for authentication feature
User.create([
  {
    name: 'Nguyen Danh Tu',
    email: 'nguyendanhtu@tudemy.vn',
    password: '12345678',
    password_confirmation: '12345678'
  }
])

Category.create([{ name: 'Test Category 1' }])

# Data for sale feature
users = User.create([
  {
    name: 'Instructor',
    email: 'instructor1@tudemy.vn',
    password: '12345678',
    password_confirmation: '12345678'
  }
])

instructor_profiles = User::InstructorProfile.create([
  {
    academic_rank: 'Doctor',
    user: users[0]
  }
])

courses = Course.create([
  {
    name: 'Test Course 1',
    price: 199000,
    alias_name: 'test-course-1',
    version: Constants::CourseVersions::PUBLIC,
    enabled: true,
    user: users[0]
  },
  {
    name: 'Test Course 2',
    price: 199000,
    alias_name: 'test-course-2',
    version: Constants::CourseVersions::PUBLIC,
    enabled: true,
    user: users[0]
  },
  {
    name: 'Test Course 3',
    price: 199000,
    alias_name: 'test-course-3',
    version: Constants::CourseVersions::PUBLIC,
    enabled: true,
    user: users[0]
  }
])  

sale_campaigns = Sale::Campaign.create([
  {
    title: 'Test Sale Campaign 1',
    start_date: Time.now,
    end_date: Time.now + 2.days
  }
])

sale_packages = Sale::Package.create([
  {
    title: 'Test Sale Package 1',
    price: 98000,
    campaign: sale_campaigns[0],
    courses: [courses[0]],
    participant_count: 2,
    max_participant_count: 10,
    start_date: Time.now,
    end_date: Time.now + 2.days
  },
  {
    title: 'Test Sale Package 2',
    price: 98000,
    campaign: sale_campaigns[0],
    courses: [courses[2]],
    participant_count: 2,
    max_participant_count: 10,
    start_date: Time.now,
    end_date: Time.now + 2.days
  }
])

discussions = courses[0].discussions.create ([
  {
    title: "OK",
    description: "OK"
  }
])

c_discussions = discussions[0].child_discussions.create ([
  {
    description: "OK"
  }
])

# Load a full course
data = File.read('/db/test_course/thiet-ke-web.json')
json = JSON.parse(data) if not data.blank?
if not json.blank?
  json.delete('discussions')
  # Create a free course
  instructor = User.where(:email => 'instructor1@tudemy.vn').first
  free_course = Course.new(json)
  free_course.price = 0
  free_course.name = "Full free course"
  free_course.alias_name = "full-free-course"
  free_course.user = instructor
  free_course.save

  # Create a paid course
  paid_course = Course.new(json)
  paid_course.price = 199000
  paid_course.name = "Full paid course"
  paid_course.alias_name = "full-paid-course"
  paid_course.user = instructor
  paid_course.save
end
