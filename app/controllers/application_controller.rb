class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?
  protected

  def configure_permitted_parameters
    # TODO adding these lines and the running `rails g migration AddNameToUsers name:string; rails g migration AddNameToUsers name:string` resulted in the error "raise ArgumentError, "Invalid route name, already in use: '#{name}'""
    #   So I don't think I need to add the name field. avatar probably requires some steps though.
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
  end
end
