class CategoryController < ApplicationController

  # POST: API create category for kelley
  def create
    name = params[:name]
    enabled = params[:enabled]
    parent_category_id = params[:parent_category_id]

    if name.blank?
      render json: {message: "Tên category không được rỗng!"}, status: :unprocessable_entity
      return
    else
      category_id = Utils.nomalize_string(name)
      exist_category = Category.where(id: category_id)
      category_id += rand(1000).to_s unless exist_category.blank?

      category = Category.new(
        _id: category_id,
        name: name,
        alias_name: category_id,
        enabled: enabled,
        parent_category_id: parent_category_id
      )

      if category.save
        render json: {message: "success!"}
        return
      else
        render json: {message: "Không lưu được data!"}, status: :unprocessable_entity
        return
      end
    end
  end

  # POST: API update category for kelley
  def update
    name = params[:name]
    alias_name = params[:alias_name]
    category_id = params[:id]
    parent_category_id = params[:parent_category_id]

    category = Category.where(id: category_id).first

    if category.blank?
      render json: {message: "category_id không đúng!"}, status: :unprocessable_entity
      return
    else
      category.name = name unless name.blank?
      category.alias_name = alias_name unless alias_name.blank?
      category.parent_category_id = parent_category_id

      if category.save
        render json: {message: "success!"}
        return
      else
        render json: {message: "Không lưu được data!"}, status: :unprocessable_entity
        return
      end
    end
  end
end