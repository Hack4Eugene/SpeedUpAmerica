class RegionController < ApplicationController

	layout "region"

  def index
    @region_submission = RegionSubmission.new
	@regionname = params[:regionname]
  end

 
  def calculate_ping
    render nothing: true
  end
end
