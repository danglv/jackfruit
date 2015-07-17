Rails.application.routes.draw do
  
  root to: "application#index"
  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks' }
  resources :courses, only: %w[index] do
    member do
      get '/lecture/:lecture_index', to: 'courses#lecture'
      get :learning
      get :detail
    end
    collection do
      get :search
      get :detail
      get '/:category_id', to: 'courses#list_course'
      get '/:category_id/all_courses', to: 'courses#all_courses'
    end
  end

  resources :payment, :path => 'home/payment', only: %w[index] do
    collection do
      get :delivery
      post :delivery
      get :visa
      get :bank
      get :direct
      get :success
    end
  end

  # match '/users/:id/finish_signup' => 'users#finish_signup', via: [:get, :patch], :as => :finish_signup
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
