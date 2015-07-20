class SupportController < ApplicationController
  def index
    name = params[:name]
    email = params[:email]
    content = params[:content]
    feedback = Feedback.create(
      :name => name,
      :email => email,
      :content => content
    )
    redirect_to session[:previous_url] || root_url
  end
end