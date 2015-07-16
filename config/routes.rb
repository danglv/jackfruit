Rails.application.routes.draw do
  
  root to: "application#index"
  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks' }
  resources :courses, only: %w[index show] do
    member do
      get :lecture
    end
    collection do
      get :search
      get :test_course_detail_id
      get :detail
    end
  end

  resources :payment, :path => 'home/payment', only: %w[index] do
    collection do
    end
  end

  match '/users/:id/finish_signup' => 'users#finish_signup', via: [:get, :patch], :as => :finish_signup
  get "/users/:id/show" => "users#show", as: :user

  resources :users, :path => 'home/my-course', only: %w[] do
    member do
      post :select_course
    end
    collection do      
      get :learning
      get :teaching
      get :wishlist
      get :search
    end
  end 

  # resources :users, :path => 'user', only: %w[] do
  #   collection do
  #     get '/:profile_url', to: 'user#index'  
  #     post :sign_up_with_email
  #     post :login_with_email
  #     post :login_with_facebook
  #     post :login_with_google
  #     post :logout
  #     put :edit_profile
  #     post :upload_avatar
  #   end    
  # end
end
