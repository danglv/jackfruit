class Users::SessionsController < Devise::SessionsController
before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    respond_with(resource, serialize_options(resource))
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    yield if block_given?
    respond_to_on_destroy
  end

  protected

  # You can put the params you want to permit in the empty array.
  def configure_sign_in_params
    devise_parameter_sanitizer.for(:sign_in) << :attribute
  end

  def after_sign_in_path_for(resource)
    referer_url = session[:referer_url] if !session.blank?
    previous_url = session[:previous_url] if !session.blank?
    referer_url = previous_url if referer_url.blank?
    utm_source = session[:utm_source] if !session.blank?
    if (referer_url)
      url_components = referer_url.match(/([^\/]*)\/detail/)
      course_alias_name = url_components[1] if url_components
      course = Course.where(:alias_name => course_alias_name).first if !course_alias_name.blank?
      if !course.blank?
        owned_course = resource.courses.where(:course_id => course.id, :payment_status => Constants::PaymentStatus::SUCCESS).first
        if owned_course
          # Tracking L3d
          Spymaster.params.cat('L3d').beh('login').tar(course.id).user(resource.id).ext(utm_source).track(request)
        else
          # Tracking L3b
          Spymaster.params.cat('L3b').beh('login').tar(course.id).user(resource.id).ext(utm_source).track(request)
        end
      end
    end
    super(resource)
  end
end
