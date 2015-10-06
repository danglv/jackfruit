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
    email: 'nguyendanhtu@tudemy.vn',
    password: '12345678',
    password_confirmation: '12345678'
  }
])

Category.create([{ name: 'Test Category 1' }])

# Data for sale feature
users = User.create([
  {
    email: 'instructor1@tudemy.vn',
    password: '12345678',
    password_confirmation: '12345678'
  },
  {
    email: 'student1@tudemy.vn',
    password: '12345678',
    password_confirmation: '12345678'
  },
  {
    email: 'student2@tudemy.vn',
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





