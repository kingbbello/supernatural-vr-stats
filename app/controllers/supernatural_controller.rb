class SupernaturalController < ApplicationController
  def index
    service = SupernaturalApiService.new
    @data = service.fetch_all_data

    if @data.present?
      render json: @data
    else
      render json: { error: "Failed to fetch data" }, status: :unprocessable_entity
    end
  end
end
