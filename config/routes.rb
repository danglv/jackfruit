require 'sidekiq/web'
Rails.application.routes.draw do
  root to: "application#index"

  mount Sidekiq::Web => '/sidekiq'
  mount RailsAdmin::Engine => '/cms', as: 'rails_admin'

  devise_for :users, :controllers => {
    omniauth_callbacks: 'omniauth_callbacks',
    registrations: 'users/registrations',
    sessions: "users/sessions"
  }

  get 'stencil/index'
  get '/home', to: redirect('/')

  resources :courses, only: %w[index] do
    member do
      # get '/lecture/:lecture_index', to: 'courses#lecture'
      # get :learning
      # get :detail
      # get '/select', to: 'courses#select'
      post :add_discussion
      post :approve
      post :add_discussion_from_wasp
      post :edit_discussion
      post :delete_discussion
      post :add_announcement
      post :add_child_announcement
      post :rating
      post :approve
      post :unpublish
    end
    
    collection do
      get :activate
      post :activate
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
      post 'upload_document', to: 'courses#upload_document'

      # API for kelley
      post :upload_course
      post :check_alias_name

      # API support form detail
      post '/api/send_form-support_detail', to: 'courses#send_form_suppot_detail'
    end
  end

  resources :contactc3s, only: %w[] do
    collection do
      post :insert
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
      post '/:id/status', to: 'payment#status'
      get '/:alias_name/payment_bill', to: 'payment#payment_bill'

      get '/test_online_payment/:alias_name', to: 'payment#test_online_payment'

      # api for mercury
      get '/api/:id/detail', to: 'payment#detail'
      post '/api/:id/update', to: 'payment#update'
      get '/api/list_payment', to: 'payment#list_payment'
    end
  end
  # match '/users/:id/finish_signup' => 'users#finish_signup', via: [:get, :patch], :as => :finish_signup
  get "/users/:id/show" => "users#show", as: :user

  get "/users/set_course_for_user" => "users#set_course_for_user", as: :set_course
  # get "/users/auth/google_oauth2/callback" => "users#auth/google_oauth2"


  resources :users, :path => 'home/my-course', only: %w[] do
    member do
    end
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

      #API create instructor for kelley
      post '/api/create_instructor', to: 'users#create_instructor'
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
      post :create_user_for_mercury
      post :create_cod_user
      get :hoc_thu
      get 'note/download', to: 'users#download_note'
      get 'payment_history' , to: 'users#payment_history'
      match '/edit_account', to: 'users#edit_account', via: [:get, :patch]
      match '/edit_avatar'  , to: 'users#edit_avatar', via: [:get, :patch]
      match '/edit_profile' , to: 'users#edit_profile', via: [:get, :patch]
      match '/reset_password' , to: 'users#reset_password', via: [:get, :patch]
      match '/forgot_password' , to: 'users#forgot_password', via: [:post]

      post '/create', to: 'users#create'
    end
  end

  resources :certificate, only: %w[] do
    collection do
      get ':certificate_no', to: 'users#certificate'
      post 'create_certificate', to: 'users#create_certificate'
    end
  end

  resources :sales do
    collection do
      get '/combo/:combo_code/detail', to: 'sales#detail'
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

  resources :label, only: %w[] do
    collection do
      # API for kelley
      post :create
      
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
  
  resources :cod, only: %w[] do
    collection do
      match '/activate' => 'cod#activate', :via => [:get, :patch]
    end
  end

  resources :faq, only: %w[] do
    collection do
      get '/change_time', to: 'faq#change_time'
      post '/error_report', to: 'faq#error_report'
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

  # Public page
  get "/404", :to => "application#page_not_found"
  get "/500", :to => "application#server_error"
end
