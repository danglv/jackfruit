class Users::RegistrationsController < Devise::RegistrationsController
before_filter :configure_sign_up_params, only: [:create]
# before_filter :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
# def new
  #   super
  # end

  # POST /resource
  def create
    build_resource(sign_up_params)
    resource.name = params[:user][:name] if not params[:user][:name].blank?
    resource_saved = resource.save
    yield resource if block_given?
    if resource_saved
      if resource.active_for_authentication?
        set_flash_message :alert, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)

        if request.referer && resource
          if request.referer.to_s.include? ('courses/activate')
            redirect_to '/courses/activate'
            return
          end
        end

        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :alert, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      set_flash_message :alert, :invalid_email if is_flashing_format?
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable        
        @minimum_password_length = resource_class.password_length.min
        set_flash_message :alert, :invalid_email if is_flashing_format?
      end
      respond_with resource
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # You can put the params you want to permit in the empty array.
  def configure_sign_up_params
    devise_parameter_sanitizer.for(:sign_up) << :attribute
  end

  # You can put the params you want to permit in the empty array.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    referer_url = session[:referer_url] if !session.blank?
    utm_source = session[:utm_source] if !session.blank?

    # Update wishlist
    wishlist_params = request.referer.blank? ? {} : (Rack::Utils.parse_query URI(request.referer).query)
    if !wishlist_params["course_id"].blank?
      course_id = wishlist_params["course_id"]
      resource.wishlist << course_id if (!(resource.wishlist.include? course_id) && !course_id.blank?)
      resource.save
    end

    # Tracking U8
    Spymaster.params.cat('U8').beh('submit').tar(resource.id).user(resource.id).ext(utm_source).track(request)
    if (referer_url)
      url_components = referer_url.match(/([^\/]*)\/detail/)
      course_alias_name = url_components[1] if url_components
      course = Course.where(:alias_name => course_alias_name).first if !course_alias_name.blank?
      if !course.blank?
        # Tracking L3a
        Spymaster.params.cat('L3a').beh('register').tar(course.id).user(resource.id).ext(utm_source).track(request)
      end
    end
    super(resource)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end
end
