Rails.application.routes.draw do  
  root to: "application#index"
  mount RailsAdmin::Engine => '/cms', as: 'rails_admin'
  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks' }

  get '/home', to: redirect('/')
  
  resources :courses, only: %w[index] do
    member do
      # get '/lecture/:lecture_index', to: 'courses#lecture'
      # get :learning
      # get :detail
      # get '/select', to: 'courses#select'
      post :add_discussion
    end
    collection do
      get :search
      get '/:category_id', to: 'courses#list_course_featured'
      get '/:category_id/all_courses', to: 'courses#list_course_all'
      get '/:alias_name/detail', to: 'courses#detail'
      get '/:alias_name/learning', to: 'courses#learning'
      get '/:alias_name/select', to: 'courses#select'
      get '/:alias_name/lecture/:lecture_index', to: 'courses#lecture'
    end
  end

  resources :payment, :path => 'home/payment', only: %w[] do
    collection do
      get '/:alias_name', to: 'payment#index'
      get '/cod/:alias_name', to: 'payment#cod'
      post :cod
      post '/cod/import_code', to: 'payment#import_code'
      get '/online_payment/:alias_name', to: 'payment#online_payment'
      get '/transfer/:alias_name', to: 'payment#transfer'
      get '/cih/:alias_name', to: 'payment#cih'
      get '/:id/status', to: 'payment#status'
      get '/:id/success', to: 'payment#success'
      get '/:id/pending', to: 'payment#pending'
      get '/:id/cancel', to: 'payment#cancel'
      # get '/:id/update', to: 'payment#update'
    end
  end

  # match '/users/:id/finish_signup' => 'users#finish_signup', via: [:get, :patch], :as => :finish_signup
  get "/users/:id/show" => "users#show", as: :user
  # get "/users/auth/google_oauth2/callback" => "users#auth/google_oauth2"

  resources :users, :path => 'home/my-course', only: %w[] do
    member do
    end
    collection do      
      get :select_course
      get :learning
      get :teaching
      get :wishlist
      get :search
    end
  end 

  resources :settings, only: %w[] do
    member do
    end

    collection do
      get :alias
    end
  end
  resources :support, only: %w[] do
    collection do
      post :index
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
