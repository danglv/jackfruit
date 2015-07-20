class SuportController < ApplicationController
  def index
    name = params[:name]
    email = params[:email]
    content = params[:content]

    feedback = Feedback.create(
                           :name => name,
                           :email => email,
                           :content => content
    )
  end
end