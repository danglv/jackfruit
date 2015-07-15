class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  # def authenticate_user
  #   @current_user = User.where(auth_token: params[:auth_token]).first
  # end

  def authenticate_user
    @current_user = User.where(auth_token: params[:auth_token]).first
  end

  def validate_content_type_param
    @content_type = params[:content_type]
    @content_type = "html" if @content_type.blank?
  end

  # action index để điều hướng đến trang landing page
  def index
    
  end
end