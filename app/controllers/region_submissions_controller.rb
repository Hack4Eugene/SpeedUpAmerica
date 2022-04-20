class RegionSubmissionsController < ApplicationController

  layout "region"

  before_action :validate_referer, only: [:show]
  before_action :initialize_stats_data, only: [:show, :embeddable_view]
  before_action :set_region_submission, only: [:show]
  before_action :set_selected_providers, only: [:region_result_page]
  before_action :set_feature_blocks, only: [:region_result_page]
  before_action :set_selected_providers_for_region_submission, only: [:show]
  before_action :set_selected_zip_codes, only: [:show]
  skip_before_action :verify_authenticity_token, only: [:embed]



  def show
  end


  def create
    data = region_submission_params

    # Use remote IP from connection or headers
    data[:ip_address] = request.remote_ip

    region_submission = RegionSubmission.create_region_submission(data)

	@regionname = region_submission.region;
    #redirect_to region_submission_path(region_submission)

	render 'region_show', locals: {region_submission: region_submission}
	#render json: data
  end

  def tileset_groupby
    data = RegionSubmission.fetch_tileset_groupby(params)
    render json: data
  rescue StandardError => e
    render status: 500, json: {'status': 'error', 'error': e.message}
  end

  def region_result_page
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

    data = RegionSubmission.internet_stats_data(statistics) || []
    render json: data
  end

  def region_export_csv
    region_render_csv
  end

  private

    def region_render_csv
      set_file_headers
      set_streaming_headers

      response.status = 200

      #setting the body to an enumerator, rails will iterate this enumerator
      self.response_body = csv_lines(params)
    end

    def set_region_submission
      @region_submission = RegionSubmission.find_by_test_id(params[:test_id])
    end

    def set_file_headers
      file_name = "region_submissions_#{Time.now.to_i}.csv"
      headers["Content-Type"] = "text/csv"
      headers["Content-disposition"] = "attachment; filename=\"#{file_name}\""
    end

    def set_streaming_headers
      headers["Cache-Control"] ||= "no-cache"
      headers.delete("Content-Length")
    end

    def csv_lines(params)
      Enumerator.new do |out|
        out << RegionSubmission.csv_header.to_s

        #ideally you'd validate the params, skipping here for brevity
        RegionSubmission.find_in_batches(params[:date_range]) do |region_submission|
          out << region_submission.to_csv_row.to_s
        end
      end
    end

    def region_submission_params
      params.require(:region_submission).permit(
        :latitude, :longitude, :accuracy, :actual_down_speed, :actual_upload_speed,
        :testing_for, :address, :zip_code, :provider, :connected_with,:access,:whynoaccess,:address,:zip_code,:monthly_price,
        :provider_down_speed, :rating, :ping, :hostname, :region
      )
    end

    def validate_referer
      redirect_to root_path if request.referer.blank? || request.referer != root_url
    end

    def initialize_stats_data
      @all_results = RegionSubmission.get_all_results
    end

    def set_selected_zip_codes
      if @region_submission.zip_code.nil?
        @selected_zip_codes = nil
        return
      end

      @selected_zip_codes = @region_submission.zip_code
    end

    def set_selected_providers_for_region_submission
      # if zip_code not set for some reason get top 3
      if @region_submission.zip_code.nil?
        return set_selected_providers
      end

      ids = RegionSubmission.unscoped.select('p.id AS id', 'count(*) AS count')
        .joins("LEFT JOIN provider_statistics AS p ON region_submissions.provider = p.name")
        .where(:zip_code => @region_submission.zip_code).where("region_submissions.test_date >= CURDATE() - INTERVAL 1 month")
        .group('p.id').order('count DESC').first(3).map(&:id)

      @selected_provider_ids = ids
    end

    def set_feature_blocks
      if request.query_parameters[:feature_blocks].present?
        @feature_blocks = true
      end
    end

    def set_selected_providers
      ids = ProviderStatistic.unscoped.order(:applications).last(3).map(&:id)
      @selected_provider_ids = ids
    end
end
