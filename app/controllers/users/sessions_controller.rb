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
    if (referer_url || previous_url)
      last_component_uri_referer = URI.parse(referer_url).path.split('/').last
      last_component_uri_previous = URI.parse(previous_url).path.split('/').last
      if (last_component_uri_referer == "detail" || last_component_uri_previous == "detail")
        url_pass_params = last_component_uri_referer == "detail" ? last_component_uri_referer : last_component_uri_previous
        uri = URI.parse(url_pass_params)
        course_alias = URI.parse(referer_url).path.split('/').last(2).first
        course = Course.where(:alias_name => course_alias).first if !course_alias.blank?
        if !course.blank?
          have_owned_course = resource.courses.map(&:course_id).include? course.id
          if !have_owned_course
            # Tracking L3b
            params = {
              Constants::TrackingParams::CATEGORY => "L3b",
              Constants::TrackingParams::TARGET => course.id,
              Constants::TrackingParams::BEHAVIOR => "login",
              Constants::TrackingParams::USER => resource.id,
              Constants::TrackingParams::EXTRAS => !uri.query.blank? ? (Rack::Utils.parse_nested_query uri.query) : {}  
            }
            track = Spymaster.track(params, request)
          else
            # Tracking L3b
            params = {
              Constants::TrackingParams::CATEGORY => "L3d",
              Constants::TrackingParams::TARGET => course.id,
              Constants::TrackingParams::BEHAVIOR => "login",
              Constants::TrackingParams::USER => resource.id,
              Constants::TrackingParams::EXTRAS => !uri.query.blank? ? (Rack::Utils.parse_nested_query uri.query) : {}  
            }
            track = Spymaster.track(params, request)
          end
        end
      end
    end
    super(resource)
  end
end
