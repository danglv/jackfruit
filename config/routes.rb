Rails.application.routes.draw do  
  get 'stencil/index'

  root to: "application#index"
  mount RailsAdmin::Engine => '/cms', as: 'rails_admin'
  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks', registrations: 'users/registrations', sessions: "users/sessions"}

  get '/home', to: redirect('/')
  
  resources :courses, only: %w[index] do
    member do
      # get '/lecture/:lecture_index', to: 'courses#lecture'
      # get :learning
      # get :detail
      # get '/select', to: 'courses#select'
      post :add_discussion
      post :add_announcement
      post :add_child_announcement
      post :rating
      post :approve
      post :unpublish
    end
    collection do
      get :search
      get '/:category_alias_name', to: 'courses#list_course_featured'
      get '/:category_alias_name/all_courses', to: 'courses#list_course_all'
      get '/:alias_name/detail', to: 'courses#detail'
      get '/:alias_name/learning', to: 'courses#learning'
      get '/:alias_name/select', to: 'courses#select'
      get '/:alias_name/lecture/:lecture_index', to: 'courses#lecture'

      # API for mercury
      get '/api/suggestion_search', to: 'courses#suggestion_search'
      get '/api/get_money', to: 'courses#get_money'
      post 'upload_image', to: 'courses#upload_image'

      # API for kelley
      post :upload_course
      post :check_alias_name
    end
  end

  resources :payment, :path => 'home/payment', only: %w[create] do
    collection do
      get '/:alias_name', to: 'payment#index'
      get '/cod/:alias_name', to: 'payment#cod'
      post :cod
      get '/cancel_cod/:course_id', to: 'payment#cancel_cod'
      post '/cod/:id/import_code', to: 'payment#import_code'
      get '/online_payment/:alias_name', to: 'payment#online_payment'
      post '/online_payment', to: 'payment#online_payment'
      get '/transfer/:alias_name', to: 'payment#transfer'
      get '/cih/:alias_name', to: 'payment#cih'
      get '/card/:alias_name', to: 'payment#card'
      post '/card/:alias_name', to: 'payment#card'

      get '/:id/status', to: 'payment#status'
      get '/:id/success', to: 'payment#success'
      get '/:id/pending', to: 'payment#pending'
      get '/:id/cancel', to: 'payment#cancel'
      get '/:id/error', to: 'payment#error'
      get '/:alias_name/payment_bill', to: 'payment#payment_bill'

      get '/test_online_payment/:alias_name', to: 'payment#test_online_payment'

      # get '/:id/update', to: 'payment#update'

      # api for mercury
      get '/api/:id/detail', to: 'payment#detail'
      post '/api/:id/update', to: 'payment#update'
      get '/api/list_payment', to: 'payment#list_payment'
    end
  end
  # match '/users/:id/finish_signup' => 'users#finish_signup', via: [:get, :patch], :as => :finish_signup
  get "/users/:id/show" => "users#show", as: :user
  # get "/users/auth/google_oauth2/callback" => "users#auth/google_oauth2"

  
  resources :users, :path => 'home/my-course', only: %w[] do
    collection do      
      get :select_course
      get :learning
      get :teaching
      get :wishlist
      get :update_wishlist
      get :search

      # API for mercury
      get '/api/suggestion_search', to: 'users#suggestion_search'
      post '/api/active_course', to: 'users#active_course'
      get '/api/:id/get_user_detail', to: 'users#get_user_detail'
      get '/api/get_course_of_instructor', to: 'users#get_course_of_instructor'

      #API create instructor for kelley
      post '/api/create_instructor', to: 'users#create_instructor'
    end
  end 
  
  resources :users, only: %w[] do

    collection do
      get :view_profile
      get :get_notes
      post :create_note
      post :update_note
      post :delete_note
      get :download_note
      get 'note/download', to: 'users#download_note'
      get 'payment_history' , to: 'users#payment_history'
      match '/edit_account', to: 'users#edit_account', via: [:get, :patch]
      match '/edit_avatar'  , to: 'users#edit_avatar', via: [:get, :patch]
      match '/edit_profile' , to: 'users#edit_profile', via: [:get, :patch]
    end
  end

  resources :sales do
    collection do
      get 'courses/combo/:combo_code', to: 'sales#combo_courses'
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
      post :send_report
    end
  end

  resources :resources, only: %w[] do
    collection do
      get '/embed/video/:course_id/(:lecture_id)', to: 'resources#embed_course_video'
      get 'lecture/doc/:doc_id', to: 'resources#lecture_doc', :as => :download_lecture_doc
    end
  end
  
  resources :label, only: %w[] do
    collection do
      # API for kelley
      post :create
      
    end

    member do
      # API for kelley
      post :update
    end
  end

  resources :category, only: %w[] do
    collection do
      # API for kelley
      post :create
      
    end

    member do
      # API for kelley
      post :update
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
