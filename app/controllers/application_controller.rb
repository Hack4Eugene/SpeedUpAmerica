class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token

  private

  def invalid_authenticity_token
    render 'shared/error', layout: false, status: 422
  end
end
