class HomeController < ApplicationController
  def index
    @submission = Submission.new
  end

  def get_location_data
    render json: Submission.get_location_data(params)
  end

  def calculate_ping
    render nothing: true
  end
end
