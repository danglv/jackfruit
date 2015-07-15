Rails.application.routes.draw do
  
  root to: "application#index"
  devise_for :users
  resources :courses, only: %w[index show] do
    collection do
      get :search
      get :test_course_detail_id
      get :detail
    end
  end

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
