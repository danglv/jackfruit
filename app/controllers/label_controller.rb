class LabelController < ApplicationController

  # POST: API create label for kelley
  def create
    name = params[:name]
    description = params[:description]
    
    if name.blank?
      render json: {message: "Tên label không được rỗng!"}, status: :unprocessable_entity
      return
    else
      label_id = Utils.nomalize_string(name)
      exist_label = Label.where(id: label_id)
      label_id += rand(1000).to_s unless exist_label.blank?

      label = Label.new(_id: label_id, name: name, description: description)


      if label.save
        render json: {message: "success!"}
        return
      else
        render json: {message: "Không lưu được data!"}, status: :unprocessable_entity
        return
      end
    end
  end

  # POST: API update label for kelley
  def update
    name = params[:name]
    description = params[:description]
    label_id = params[:id]
    label = Label.where(id: label_id).first

    if label.blank?
      render json: {message: "label_id không đúng!"}, status: :unprocessable_entity
      return
    else
      label.name = name unless name.blank?
      label.description = description unless description.blank?

      if label.save
        render json: {message: "success!"}
        return
      else
        render json: {message: "Không lưu được data!"}, status: :unprocessable_entity
        return
      end
    end
  end
end