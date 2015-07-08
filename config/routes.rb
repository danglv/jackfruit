Rails.application.routes.draw do
  
  resources :courses, only: %w[index show] do
    collection do
      get :search
    end
  end

  resources :users, :path => 'home/my-course', only: %w[index] do
    collection do
      get :learning
      get :teaching
      get :wishlist
      get :search
    end
  end 
end
