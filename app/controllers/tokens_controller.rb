class TokensController < ApplicationController
  before_filter :require_registered_user
  before_filter { |c| c.active_tab = "profile" }
  before_filter :require_password_session
  before_filter :require_non_masquerading, :except => :show

  def require_non_masquerading
    render_unauthorized_action if @real_current_user
  end

  def create
    params[:access_token].delete :token
    params[:access_token][:developer_key] = DeveloperKey.default
    @token = @current_user.access_tokens.build(params[:access_token])
    if @token.save
      render :json => @token.as_json(:include_root => false, :methods => [:app_name,:visible_token])
    else
      render :json => @token.errors, :status => :bad_request
    end
  end
  
  def destroy
    @token = @current_user.access_tokens.find(params[:id])
    @token.destroy
    render :json => @token.as_json(:include_root => false)
  end
  
  def update
    @token = @current_user.access_tokens.find(params[:id])
    if @token.update_attributes(params[:access_token])
      render :json => @token.as_json(:include_root => false, :methods => [:app_name,:visible_token])
    else
      render :json => @token.errors, :status => :bad_request
    end
  end
  
  def show
    @token = @current_user.access_tokens.find(params[:id])
    render :json => @token.as_json(:include_root => false, :methods => [:app_name,:visible_token])
  end
  
end
