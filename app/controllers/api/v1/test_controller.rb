class Api::V1::TestController < ApplicationController
  def index
    render json: { message: "Rails app is running" }
  end
end
