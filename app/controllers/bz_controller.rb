# This holds BZ custom endpoints for updating our
# custom data.

class BzController < ApplicationController

  before_filter :require_user, :only => [:last_user_url]
  skip_before_filter :verify_authenticity_token, :only => [:last_user_url]

  def last_user_url
    @current_user.last_url = params[:last_url]
    @current_user.last_url_title = params[:last_url_title]
    @current_user.save

    render :nothing => true
  end
end
