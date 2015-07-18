class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  def ensure_signup_complete
    # Ensure we don't go into an infinite loop
    return if action_name == 'finish_signup'

    # Redirect to the 'finish_signup' page if the user
    # email hasn't been verified yet
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end

  # def authenticate_user
  #   current_user = User.where(auth_token: params[:auth_token]).first
  # end

  def validate_content_type_param
    @content_type = params[:content_type]
    @content_type = "html" if @content_type.blank?
  end

  # action index để điều hướng đến trang landing page
  def index
    @courses = Course.all.desc(:students).limit(8)

    if current_user
      redirect_to root_url + "courses"
    end

  end

  def list_category
    @all_categories = []
    @parent_category_id = nil
    @level = 0

    categories_level_0 = Category.where(:parent_category_id => nil)

    categories_level_0.each {|category|
      sub_categories = Category.where(:parent_category_id => category.id)
      parent_cate = [category.id, category.name, []]
      sub_categories.each {|sub_cate|
        parent_cate[2] << [sub_cate.id, sub_cate.name]
      }
      @all_categories << parent_cate
    }
  end
  # def list_category
  #   @all_categories = []
  #   @parent_category_id = nil
  #   @level = 0

  #   @list_categories = Category.only(:id, :name, :parent_category_id).all.as_json
  #   recursive_category(@all_categories, @parent_category_id, @level, @list_categories)
  # end
  
  # private
  #   def recursive_category(all_categories, parent_category_id, level, list_categories)
  #     categories = @list_categories.select{|c| c["parent_category_id"] == parent_category_id}
  #     if categories.count == 0
  #       level -= 1
  #     else
  #       categories.each {|category|
  #         all_categories << [category["_id"], category["name"], level]
  #         parent_category_id = category["_id"]
  #         recursive_category(all_categories, parent_category_id, level + 1, list_categories)
  #       }
  #     end
  #   end
end