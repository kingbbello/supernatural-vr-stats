class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def set_timezone
    session[:timezone] = params[:timezone] if params[:timezone].present?
    head :ok
  end
end
