class SubmissionsController < ApplicationController
  before_action :initialize_stats_data, only: [:show, :embeddable_view]
  before_action :set_selected_providers, only: [:show, :result_page]
  skip_before_action :verify_authenticity_token, only: [:embed]

  def show
    @submission = Submission.find(params[:id])
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
  end

  def embeddable_view
  end

  def export_csv
    send_data Submission.to_csv(params[:date_range]), filename: "submissions - #{Time.now}.csv"
  end

  def speed_data
    data = params[:statistics].present? && Submission.internet_stats_data(params[:statistics]) || []
    render json: data
  end

  def isps_data
    data = Submission.service_providers_data(params[:type], params[:categories], params[:connection_type], params[:provider])
    render json: data
  end

  private
    def submission_params
      params.require(:submission).permit(:latitude, :longitude, :actual_down_speed, :actual_upload_speed, :testing_for, :address, :zip_code, :provider, :connected_with, :monthly_price, :provider_down_speed, :rating, :ping, :ip_address, :hostname)
    end

    def initialize_stats_data
      @all_results, @home_submissions, @mobile_submissions, @public_submissions, @total_submissions, @home_avg_speed_by_zipcode = Submission.stats_data
    end

    def set_selected_providers
      @selected_provider_ids = ProviderStatistic.order(:applications).last(3).map(&:id)
    end
end
