class RegionController < ApplicationController

	layout "region"

  def index
    @region_submission = RegionSubmission.new
	@regionname = params[:regionname.downcase]

	if (:regionname.downcase == 'oregon') 
		@disclaimerlink = 'I agree to the <a href="https://www.measurementlab.net/privacy/" target="_blank" >data policy</a> and have read the <a href="https://test.fasterinternetoregon.org/disclaimer/"  target="_blank">disclaimer</a>'.html_safe
	else
		@disclaimerlink = 'I agree to the <a href="https://www.measurementlab.net/privacy/" target="_blank" >data policy</a> and have read the <a href="https://test.fasterinternetoregon.org/disclaimer/"  target="_blank">disclaimer</a>'.html_safe
	end

  end

 
  def calculate_ping
    render nothing: true
  end
end
