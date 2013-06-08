class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user, :logged_in?

  before_filter :https_redirect

  private

  def https_redirect
    #if ENV["ENABLE_HTTPS"] == "yes"
      if request.ssl? && !use_https? || !request.ssl? && use_https?
        protocol = request.ssl? ? "http" : "https"
        flash.keep
        redirect_to protocol: "#{protocol}://", status: :moved_permanently
      end
    #end
  end

  def use_https?
    false # Override in other controllers
  end


  def current_user
    # hack to dev
    u = User.find_by_id(session[:user_id])
    if !u
      session[:user_id] = nil
    end
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    !!current_user
  end
  
  def require_login
    if !logged_in?
      session[:return_to_url] = request.url if session # robots have session turned off
      redirect_to :root, :notice => "Sign Up or Login to access Bobfather"
    end
  end
  
end
