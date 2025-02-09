class SupernaturalController < ApplicationController
  before_action :set_timezone
  
  def index
    service = SupernaturalApiService.new
    @feed = service.fetch_all_data
    
    if @feed.present?
      render :index
    else
      render json: { error: "Failed to fetch data" }, status: :unprocessable_entity
    end
  end

  def chart_data
    days = params[:days].to_i 
    metric = params[:metric]
    
    service = SupernaturalApiService.new
    feed = service.fetch_all_data
    puts "feed: #{feed.first["body"]["closed_at"]}"
    puts "converted: #{Time.zone.parse(feed.first["body"]["closed_at"])}"

    sorted_workouts = feed.each_with_object({}) do |workout, hash|
      # Convert to application timezone before formatting
      date = Time.zone.parse(workout["body"]["closed_at"]).strftime("%Y-%m-%d")
      accuracy = workout["body"]["accuracy_percentage_str"]
      power = workout["body"]["total_power_percentage_str"]
      total_time = workout["body"]["total_time"].to_f
      total_hits = workout["body"]["total_hits"].to_i
      
      next if power.nil? || power.empty? || power == "0"
      
      # Initialize or update the date's workout count and metrics
      hash[date] ||= {
        accuracy_percentage: 0.0,
        power_percentage: 0.0,
        total_time: 0.0,
        workout_count: 0,
        total_hits: 0
      }
      
      hash[date][:accuracy_percentage] = accuracy.to_f
      hash[date][:power_percentage] = power.to_f
      hash[date][:total_time] += total_time
      hash[date][:workout_count] += 1
      hash[date][:total_hits] += total_hits
    end

    filtered_workouts = sorted_workouts
      .select { |date, _| Date.parse(date) >= days.days.ago.to_date }
      .sort_by { |date, _| date }
      .to_h
    
    data = case metric
    when 'accuracy'
      filtered_workouts.transform_values { |v| v[:accuracy_percentage].to_f }
    when 'power'
      filtered_workouts.transform_values { |v| v[:power_percentage].to_f }
    when 'time'
      filtered_workouts.transform_values { |v| v[:total_time] / (1000.0 * 60.0) }
    when 'workouts'
      filtered_workouts.transform_values { |v| v[:workout_count] }
    when 'speed'
      filtered_workouts.transform_values { |v| v[:total_hits] / (v[:total_time] / 1000.0) } # hits per second
    when 'hits'
      filtered_workouts.transform_values { |v| v[:total_hits] }
    end
    
    render json: data
  end

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

  private
  
  def set_timezone
    # Fall back to application default timezone if client timezone isn't set
    Time.zone = session[:timezone] || Rails.application.config.time_zone
  end
end
