Rails.application.routes.draw do
  
  resources :courses, only: %w[index] do
    member do
      get :course_detail
    end

    collection do
      get :list
    end
  end

end
