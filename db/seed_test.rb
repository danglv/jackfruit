# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Load a full course
# data = File.read('db/test_course/thiet-ke-web.json')
# json = JSON.parse(data) if not data.blank?
# if not json.blank?
#   json.delete('discussions')
#   # Create a free course
#   instructor = User.where(:email => 'instructor1@tudemy.vn').first
#   free_course = Course.new(json)
#   free_course.price = 0
#   free_course.name = "Full free course"
#   free_course.alias_name = "full-free-course"
#   free_course.user = instructor
#   free_course.save

#   # Create a paid course
#   paid_course = Course.new(json)
#   paid_course.price = 199000
#   paid_course.name = "Full paid course"
#   paid_course.alias_name = "full-paid-course"
#   paid_course.user = instructor
#   paid_course.save
# end
