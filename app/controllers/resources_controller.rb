class ResourcesController < ApplicationController
	layout 'embed'

	def embed_course_video
		@video_url = nil
		return if !params[:course_id]
		course = Course.where(:id => params[:course_id]).first
		return if !course
		if !params[:lecture_id]
			@video_url = course.intro_link
			@image_url = course.intro_image if @video_url.blank?
		else
			lecture = course.curriculums.where(:id => lecture_id).first
			return if !lecture
			@video_url = lecture.url
		end
	end

	def lecture_doc
		send_file "resources/lecture/demo_doc.txt"
	end
end