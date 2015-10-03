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
    # Track L3b, from detail, sign in, and hasn't had course
    
    previous_url = nil
    previous_url = session[:previous_url] if !session.blank?

    if previous_url
      course_alias = nil
      uri = URI.parse(previous_url)
      if uri.query
        uri_params = CGI.parse(uri.query)
        course_alias = uri_params["alias_name"].first if uri_params["alias_name"].count > 0
      else
        course_alias = URI.parse(previous_url).path.split('/').last(2).first
      end
      course = Course.where(:alias_name => course_alias).first if !course_alias.blank?
      last_component_url = URI.parse(previous_url).path.split('/').last
      if (["select_course", "detail"].include? last_component_url) && !course.blank?
        # Tracking L3b
        params = {
          Constants::TrackingParams::CATEGORY => "L3b",
          Constants::TrackingParams::TARGET => course.id,
          Constants::TrackingParams::BEHAVIOR => "login",
          Constants::TrackingParams::USER => resource.id,
          Constants::TrackingParams::EXTRAS => {
            :chanel => (request.params['utm_source'].blank? ? request.referer : request.params['utm_source'])
          }
        }
        track = Spymaster.track(params, request.blank? ? nil : request)
      end
    end
    super(resource)
  end
end
