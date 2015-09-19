class Course::Document
	include Mongoid::Document

	field :type, type: String
	field :title, type: String
	field :link, type: String

	embedded_in :curriculums
end