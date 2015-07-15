class CoursesController < ApplicationController

  before_filter :validate_content_type_param

  def index
    category_name = params[:category]
    
    category = Category.where(name: category_name).first
    
    if category.blank?
      labels = Constants.LabelsValues
      @courses = {}

      labels.each {|label|
        @courses[label.to_sym] = Course.where(:label_ids.in => [label]).limit(12)
      }
    else
      sort_by = params[:sort_by]
      condition = params[:filter_by]
      if condition[:price]
        condition[:price.gt] = 0
        condition.delete[:price]
      end

      @courses = {}
      condition.each{|fil| condition.delete(fil[0].to_sym) if fil[1] == nil}
      condition[:category_ids.in] = [category.id]

      @courses["featured"] = Course.where(
        :label_ids.in => ["featured"],
        :category_ids.in => [category.id]).first

      @courses["top_free"] = Course.where(
        :price => 0,
        :category_ids.in => [category.id]
      ).desc(:students).limit(12)

      @courses["top_paid"] = Course.where(
        :price.gt => 0,
        :category_ids.in => [category.id]
      ).desc(:students).limit(12)

      @courses["newest"] = Course.where(
        :category_ids.in => [category.id],
      ).desc(:created_at).limit(12)

      @courses["all"] = Course.where(condition).sort(sort_by)
    end
  end

  def show
    course_id = params[:id]
    @course = Course.where(id: course_id).first
  end

  def search
    keywords = params[:q]
    pattern = /#{Regexp.escape(keywords)}/
    @course = Course.where(name: pattern).limit(10)

    if @course.count == 0
      @course = Course.where(description: pattern).limit(10)
    end
  end

  def test_course_detail_id

  end
end