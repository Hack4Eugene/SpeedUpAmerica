class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token

  def rescue_from_invalid_url
    redirect_to root_url, alert: 'We are sorry, this is an invalid URL.'
  end

  private

  def invalid_authenticity_token
    render 'shared/error', layout: false, status: 422
  end
end
