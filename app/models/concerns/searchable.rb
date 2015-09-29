require 'elasticsearch/model'

module Searchable
  extend ActiveSupport::Concern
  included do  
    include Elasticsearch::Model
    def as_indexed_json
      self.as_json({
        include: {
          curriculums: {only: :title},
          user: {only: [:name,:instructor_profile,:biography]}
        },
        only: [:name, :benefit, :sub_title, :description, :price, :version, :enabled, :lang, :level]
      })
    end
  end
end