class ResourcesController < ApplicationController
	before_filter :authenticate_user!, only: [:lecture_doc]
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
		lecture_id = params[:lecture_id]
		doc_id = params[:doc_id]

		begin
			lecture_id = BSON::ObjectId.from_string lecture_id
		rescue BSON::ObjectId::Invalid
			return
		end

		if course = Course.where('curriculums._id' => lecture_id).first
			if lecture = course.curriculums.where(:id => lecture_id).first
				if doc = true
					send_file "resources/lecture/demo_doc.txt"
					return
				end
			end
		end
		# Render not found page
	end
end