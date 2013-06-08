class RedirectController < ApplicationController
  
  def index
    render :layout => false
  end


  def use_https?
    true # Override in other controllers
  end

end