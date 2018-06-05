class SubmissionsController < ApplicationController
  before_action :initialize_stats_data, only: [:show, :result_page]

  def show
    redirect_to root_path if request.referer.blank? || request.referer != root_url
    @submission = Submission.find(params[:id])
    @all_results = Submission.get_all_results
  end

  def create
    submission = Submission.create_submission(submission_params)
    redirect_to submission_path(submission)
  end

  def mapbox_data
    data = Submission.fetch_mapbox_data(params)
    render json: data
  end

  def result_page
    @all_results = Submission.get_all_results
  end

  def export_csv
    send_data Submission.to_csv, filename: "submissions - #{Time.now}.csv"
  end

  def internet_stats
    @home_submissions = Submission.in_zip_code_list.with_connection_type(Submission::MAP_FILTERS[:connection_type][:home_wifi])
    @mobile_submissions = Submission.in_zip_code_list.with_connection_type(Submission::MAP_FILTERS[:connection_type][:mobile_data])
    @public_submissions = Submission.in_zip_code_list.with_connection_type(Submission::MAP_FILTERS[:connection_type][:public_wifi])
    @total_submissions = @home_submissions.count + @mobile_submissions.count + @public_submissions.count
    @home_avg_speed_by_zipcode = Submission.average_speed_by_zipcode(@home_submissions)
  end

  def speed_data
    data = Submission.download_speed_data(params[:connection_type], params[:categories], params[:provider])
    render json: data
  end

  def isps_data
    data = Submission.service_providers_data(params[:type], params[:categories], params[:connection_type], params[:provider])
    render json: data
  end

  def change_zipcode
    respond_to do |format|
      format.js
    end
  end

  private
    def submission_params
      params.require(:submission).permit(:latitude, :longitude, :actual_down_speed, :actual_upload_speed, :testing_for, :address, :zip_code, :provider, :connected_with, :monthly_price, :provider_down_speed, :rating, :ping, :internet_location, :provider_upload_speed)
    end

    def initialize_stats_data
      @all_results, @home_submissions, @mobile_submissions, @public_submissions, @business_submissions, @total_submissions, @home_median_speed_by_zipcode = Submission.stats_data
    end
end
