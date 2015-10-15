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

    if request.referer && resource
  		last_component_referer_url = URI(request.referer).path.split('/').last
  		if last_component_referer_url == "hoc_thu.html"
				RestClient.post('http://crm.pedia.topica.vn/admin/api/UpLevel/UpLevelAuto',
          timeout: 2000,
          email: resource.email
        )
        redirect_to "http://pedia.vn/courses/tu-duy-lam-chu-se-thay-doi-cuoc-doi-ban-nhu-the-nao/detail" and return
  		end
  	end

    respond_with resource, location: after_sign_in_path_for(resource)
    return
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
    handle_after_signin(resource)
    super(resource)
  end
end
