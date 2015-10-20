class ResourcesController < ApplicationController
	# before_filter :authenticate_user!, only: [:lecture_doc]
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
		begin 
			doc_id = params[:doc_id]
			begin
				doc_id = BSON::ObjectId.from_string doc_id
			rescue BSON::ObjectId::Invalid
				return
			end
			# I am afraid that this work may cost time
			# In fact, it hits database just one time for querying the course
			# Plus, downloading documents is not a frequent stuff
			# Anyway, should pay attention on this job
			if course = Course.where('curriculums.documents._id' => doc_id).first
				
				if lecture = course.curriculums.where('documents._id' => doc_id).first

					# https://github.com/rubyzip/rubyzip zip file
					if doc = lecture.documents.where(:id => doc_id).first
						fremote =  open(URI("https://static.pedia.vn/#{doc.link}"))
						send_data fremote.read, :disposition => 'attachment'
						return
					end
				end
			end
		rescue
			render text: "File not exist !"
		end
		# Render not found page
	end
end