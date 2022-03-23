class RegionController < ApplicationController

	layout "region"

  def index
    @submission = Submission.new
	@regionname = params[:regionname]
  end

 
  def calculate_ping
    render nothing: true
  end
end
