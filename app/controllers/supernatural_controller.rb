class SupernaturalController < ApplicationController
  def index
    service = SupernaturalApiService.new
    @feed = service.fetch_all_data
    @workout_counts = {}  # Initialize the workout counts hash

    @sorted_workouts = @feed.each_with_object({}) do |workout, hash|
      date = Date.parse(workout["body"]["closed_at"]).strftime("%Y-%m-%d")
      accuracy = workout["body"]["accuracy_percentage_str"]
      power = workout["body"]["total_power_percentage_str"]
      total_time = workout["body"]["total_time"].to_f
      
      # Skip if accuracy is nil, empty, or "0"
      next if power.nil? || power.empty? || power == "0"
      
      accuracy_float = accuracy.to_f
      power_float = power.to_f
      
      if hash[date]
        # Calculate new averages when adding to existing date
        existing_count = @workout_counts[date]
        hash[date] = {
          accuracy_percentage: ((hash[date][:accuracy_percentage] * existing_count) + accuracy_float) / (existing_count + 1),
          power_percentage: ((hash[date][:power_percentage] * existing_count) + power_float) / (existing_count + 1),
          total_time: hash[date][:total_time] + total_time  # Sum up total time
        }
        @workout_counts[date] += 1
      else
        # Initialize new date with first scores
        hash[date] = {
          accuracy_percentage: accuracy_float,
          power_percentage: power_float,
          total_time: total_time
        }
        @workout_counts[date] = 1
      end
    end

    # Calculate separate minimums for percentages and time
    percentage_scores = @sorted_workouts.values.flat_map { |v| [v[:accuracy_percentage], v[:power_percentage]] }
    time_scores = @sorted_workouts.values.map { |v| v[:total_time] / (1000.0 * 60.0) }
    
    @min_percentage = percentage_scores.min ? [(percentage_scores.min - 5).floor, 0].max : 0
    @min_time = time_scores.min ? [(time_scores.min - 1).floor, 0].max : 0
    
    if @feed.present?
      render :index
    else
      render json: { error: "Failed to fetch data" }, status: :unprocessable_entity
    end
  end

  private

  def key_metrics
    [
      "accuracy_percentage_str",
      "accuracy_points",
      "total_power_points",
      "total_power_hits",
      "max_power_hits",
      "total_hits",
      "total_time",
      "total_power_percentage_str"
    ]
  end
end
