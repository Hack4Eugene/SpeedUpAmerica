class HomeController < ApplicationController
  def index
    @submission = Submission.new
  end

  def get_location_data
    if params[:longitude].nil? || params[:longitude].nil?
      render :json => { :error => "Invalid value for latitude or longitude" }, :status => 400
      return
    end

    data = Submission.get_location_data(params)
    render json: data
  end

  def calculate_ping
    render nothing: true
  end
end
