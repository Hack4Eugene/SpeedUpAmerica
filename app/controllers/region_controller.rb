class RegionController < ApplicationController

	layout "region"

  def index
    @region_submission = RegionSubmission.new
	@regionname = params[:regionname.downcase]

	# get the language
	lang = 'en'
	suffix = @regionname[-3, 3]
	if (suffix == '-es')
		lang = 'es'
	end

	@language = lang
	@suffix = suffix

	if (@language == 'es') 
		@disclaimerlink = 'He leído la <a href="https://www.measurementlab.net/privacy/" target="_blank" >política de datos</a> y <a href="https://test.fasterinternetoregon.org/es/disclaimer/"  target="_blank">el descargo de responsabilidad</a>'.html_safe
	elsif (:regionname.downcase == 'oregon') 
		@disclaimerlink = 'I agree to the <a href="https://www.measurementlab.net/privacy/" target="_blank" >data policy</a> and have read the <a href="https://test.fasterinternetoregon.org/disclaimer/"  target="_blank">disclaimer</a>'.html_safe
	else
		@disclaimerlink = 'I agree to the <a href="https://www.measurementlab.net/privacy/" target="_blank" >data policy</a> and have read the <a href="https://test.fasterinternetoregon.org/disclaimer/"  target="_blank">disclaimer</a>'.html_safe
	end

  end

 
  def calculate_ping
    render nothing: true
  end
end
