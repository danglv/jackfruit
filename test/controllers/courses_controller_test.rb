require 'test_helper'
describe 'CoursesController' do
	# Init databases Test
	before do
		@users = User.create([
			{
				email: 'instructor@pedia.vn',
				password: '12345678',
				password_confirmation: '12345678'
			},
			{
				email: 'student@pedia.vn',
				password: '12345678',
				password_confirmation: '12345678',
				role: "user"
			}
		])

		@labels = Label.create([
			{
				_id: "featured", 
				name: "featured", 
				description: "Nổi bật", 
				type: "category"
			},
			{
				_id: homepage,
				name: "homepage", 
				description: "Display at homepage", 
				type: "category"
			}
		])

		@courses = Course.create([
			{
				name: 'Test course 1',
				price: 0,
				alias_name: 'test_course_1',
				user: @user[0],
				curriculums: [],
				labels: [@labels[0]]
			},
			{
				name: 'Test course 2',
				price: 199000,
				alias_name: 'test_course_2',
				user: @user[0],
				curriculums: [],
				labels: [@labels[1]]
			},
			{
				name: 'Test course 3',
				price: 699000,
				alias_name: 'test_course_3',
				user: @user[0],
				curriculums: [],
				labels: @labels
			},
			{
				name: 'Test course 4',
				price: 699000,
				alias_name: 'test_course_4',
				user: @user[0],
				curriculums: [],
				labels: @labels,
				version: Constants::CourseVersions::TEST
			}
		])

		sign_in @users[1]
	end

	after do
		User.delete_all
		Course.delete_all
	end
end