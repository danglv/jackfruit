Rails.application.routes.draw do
  
  resources :courses do
    member do
      get :course_detail
    end

    collection do
      get :list
    end
  end

  resources :demo ,only:%w[] do
  	collection do
  		get :test
  	end
  end

end
