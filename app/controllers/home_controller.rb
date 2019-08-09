class HomeController < ApplicationController
  def index
    @submission = Submission.new
  end

  def calculate_ping
    render nothing: true
  end
end
