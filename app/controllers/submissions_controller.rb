class SubmissionsController < ApplicationController
  before_action :validate_referer, only: [:show]
  before_action :initialize_stats_data, only: [:show, :embeddable_view]
  before_action :set_selected_providers, only: [:show, :result_page]
  skip_before_action :verify_authenticity_token, only: [:embed]

  def show
    @submission = Submission.find(params[:id])
  end

  def create
    data = submission_params

    # Use remote IP from connection or headers
    data[:ip_address] = request.remote_ip

    submission = Submission.create_submission(data)
    redirect_to submission_path(submission)
  end

  def tileset_groupby
    data = Submission.fetch_tileset_groupby(params)
    render json: data
  rescue StandardError => e
    render status: 500, json: {'status': 'error', 'error': 'problem getting stats'}
  end

  def result_page
  end

  def embeddable_view
  end

  def speed_data
    if params[:statistics].nil?
      render status: 400, json: {'status': 'error', 'error': 'Bad request: missing statistics'}
    end

    statistics = params[:statistics]

    if statistics[:provider].nil?
      render status: 400, json: {'status': 'error', 'error': 'Bad request: missing provider'}
    end

    data = Submission.internet_stats_data(statistics) || []
    render json: data
  end

  def isps_data
    data = Submission.service_providers_data(params[:type], params[:categories], params[:connection_type], params[:provider])
    render json: data
  end

  def export_csv
    # send_data Submission.to_csv(params[:date_range]), filename: "submissions - #{Time.now}.csv"
    render_csv
  end

  private

    def render_csv
      set_file_headers
      set_streaming_headers

      response.status = 200

      #setting the body to an enumerator, rails will iterate this enumerator
      self.response_body = csv_lines(params)
    end

    def set_file_headers
      file_name = "submissions_#{Time.now.to_i}.csv"
      headers["Content-Type"] = "text/csv"
      headers["Content-disposition"] = "attachment; filename=\"#{file_name}\""
    end

    def set_streaming_headers
      headers["Cache-Control"] ||= "no-cache"
      headers.delete("Content-Length")
    end

    def csv_lines(params)
      Enumerator.new do |out|
        out << Submission.csv_header.to_s

        #ideally you'd validate the params, skipping here for brevity
        Submission.find_in_batches(params[:date_range]) do |submission|
          out << submission.to_csv_row.to_s
        end
      end
    end

    def submission_params
      params.require(:submission).permit(
        :latitude, :longitude, :accuracy, :actual_down_speed, :actual_upload_speed,
        :testing_for, :address, :zip_code, :provider, :connected_with, :monthly_price,
        :provider_down_speed, :rating, :ping, :hostname
      )
    end

    def validate_referer
      redirect_to root_path if request.referer.blank? || request.referer != root_url
    end

    def initialize_stats_data
      @all_results, @home_submissions, @mobile_submissions, @public_submissions, @total_submissions, @home_avg_speed_by_zipcode = Submission.stats_data
    end

    def set_selected_providers
      ids = ProviderStatistic.unscoped.order(:applications).last(3).map(&:id)
      @selected_provider_ids = ids
    end
end
