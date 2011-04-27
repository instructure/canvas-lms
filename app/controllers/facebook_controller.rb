#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class FacebookController < ApplicationController
  include Facebooker::Rails::Controller
  protect_from_forgery :only => []
  before_filter :get_facebook_user
  filter_parameter_logging :fb_sig_friends
  
  def install_url
    @facebook_session.install_url(:next => "#{facebook_host}/facebook/authorize_user?oauth_request_id=#{@oauth_request && @oauth_request.id}&fb_key=#{params[:fb_key]}") #rescue "#"
  end
  
  def facebook_host
    return "http://#{@original_host_with_port}" if @original_host_with_port
    HostUrl.default_host
  end

  def authorize_user
    @oauth_request ||= OauthRequest.find_by_id(params[:oauth_request_id]) if params[:oauth_request_id].present?
    if @oauth_request && @oauth_request.original_host_with_port != request.host_with_port
      @original_host_with_port = @oauth_request.original_host_with_port
      redirect_to install_url
      return
    end
    user_id = params[:user_id]
    nonce = Digest::MD5.hexdigest(user_id.to_s + "_instructure_verified--for_facebook")
    if nonce == params[:nonce] || @oauth_request || @authorized_facebook_session || session[:facebook_user_authorized]
      @facebook_user_id ||= user_id
      @facebook_user_id = session[:facebook_user_id] if session[:facebook_user_authorized]
      if @facebook_user_id && (@oauth_request || @current_user)
        if @oauth_request
          @service = UserService.find_or_create_by_service_user_id_and_service(@facebook_user_id, 'facebook')
          @oauth_user = @oauth_request.user
        else
          @service = UserService.find_or_create_by_service_user_id_and_service(@facebook_user_id, 'facebook')
          @oauth_user = @current_user
        end
        @facebook_session.user.populate(:name)[:name] rescue nil
        @service.service_user_name = @facebook_session.user.name rescue @service.service_user_name
        @service.service_user_name = session[:facebook_user_name] if session[:facebook_user_authorized]
        @oauth_user.user_services.of_type('facebook').each{|s| s.update_attributes(:user_id => nil) unless s == @service }
        @service.update_attributes(:user => @oauth_user)
        session[:facebook_user_authorized] = nil
        redirect_to "http://apps.facebook.com/#{Facebooker.facebooker_config['canvas_page_name']}?just_authorized=1&fb_key=#{params[:fb_key]}"
      else
        session[:facebook_user_authorized] = true
        session[:facebook_user_id] = @facebook_user_id
        @facebook_session.user.populate(:name)[:name] rescue nil
        session[:facebook_user_name] = @facebook_session.user.name rescue nil
        flash[:notice] = "Facebook Canvas App successfully installed! You still need to authorize its use within Canvas."
        redirect_to "http://apps.facebook.com/#{Facebooker.facebooker_config['canvas_page_name']}"
      end
    else
      flash[:notice] = "You must be logged in to link your Facebook account"
      redirect_to login_url(:host => HostUrl.default_host)
    end
  end
  
  def notification_preferences
    if request_comes_from_facebook? && @user
      @cc = @user.communication_channels.find_by_path_type('facebook')
      if @cc
        @old_policies = @user.notification_policies.for_channel(@cc)
        @policies = []
        params[:types].each do |type, frequency|
          notifications = Notification.find_all_by_category(type)
          notifications.each do |notification|
            pref = @user.notification_policies.new
            pref.notification_id = notification.id
            pref.frequency = frequency
            pref.communication_channel_id = @cc.id
            @policies << pref unless frequency == 'never'
          end
        end
        NotificationPolicy.transaction do
          @old_policies.each{|p| p.destroy}
          @policies.each{|p| p.save!}
        end
      end
      @notification_categories = Notification.dashboard_categories.reject{|c| c.category == "Summaries"}
      @policies = @user.notification_policies.for_channel(@cc)
      render :partial => "notification_policies.fbml.erb"
      # render partial for settings
    else
      render :text => "Bad Request", :status => :bad_request
    end
  end
  
  def about
    @service = UserService.find_by_service_user_id_and_service(@facebook_user_id, 'facebook')
    @user = @service.user if @service
    if params[:fb_key]
      @oauth_request ||= OauthRequest.find_by_secret_and_service(params[:fb_key], 'facebook')
    end
    respond_to do |format|
      format.fbml { render :action => 'about', :layout => false }
    end
  end
  
  def index
    flash[:notice] = "Authorization successful!  Canvas and Facebook are now friends." if params[:just_authorized]
    @session_user = @facebook_session.user rescue nil
    @session_user.dashboard_count = 0 if @session_user
    @messages = []
    if @user
      @messages = Message.for_user(@user.id).to_facebook.to_a
      @domains = @user.pseudonyms.scoped({:include => :account}).to_a.once_per(&:account_id).map{|p| HostUrl.context_host(p.account) }.uniq
    end
    respond_to do |format|
      format.fbml { render :action => 'index', :layout => false }
    end
  end
  
  def settings
    @notification_categories = Notification.dashboard_categories
    @cc = @user && @user.communication_channels.find_by_path_type('facebook')
    @policies = @user && @user.notification_policies.for_channel(@cc)
    respond_to do |format|
      format.fbml { render :action => 'settings', :layout => false }
    end
  end
  
  def add_user
    if request_comes_from_facebook?
      @service = UserService.find_or_initialize_by_service_user_id_and_service(params[:fb_sig_user], 'facebook')
      @service.save
    end
    render :text => "Added"
  end
  
  def remove_user
    if request_comes_from_facebook?
      @service = UserService.find_by_service_user_id_and_service(params[:fb_sig_user], 'facebook')
      @service.destroy if @service
    end
    render :text => "Deleted"
  end
  
  def facebook_disabled?
    if !feature_and_service_enabled?(:facebook) 
      respond_to do |format|
        format.fbml { render :action => 'index_disabled', :layout => false }
      end
      return true
    end
  end
  
  def get_facebook_user
    return false if facebook_disabled?
    create_facebook_session rescue nil
    @facebook_user_id = @facebook_session.user.to_i if (@facebook_session && @facebook_session.user rescue false)
    @authorized_facebook_session = @facebook_session
    @oauth_request = OauthRequest.find_by_token_and_service(@facebook_session.session_key, 'facebook') if @facebook_session
    if params[:fb_key]
      @oauth_request ||= OauthRequest.find_by_secret_and_service(params[:fb_key], 'facebook')
      if @oauth_request && @facebook_user_id
        if @oauth_request
          @service = UserService.find_or_create_by_service_user_id_and_service(@facebook_user_id, 'facebook')
          @oauth_user = @oauth_request.user
        else
          @service = UserService.find_or_create_by_service_user_id_and_service(@facebook_user_id, 'facebook')
          @oauth_user = @current_user
        end
        @oauth_request.token = @facebook_session.session_key if @facebook_session
        @oauth_request.save
        @service = @oauth_request.user.user_services.find_or_create_by_service_user_id_and_service(nil, 'facebook')
        @service.service_user_id = @facebook_user_id
        @oauth_user.user_services.of_type('facebook').each{|s| s.update_attributes(:user_id => nil) unless s == @service }
        @facebook_session.user.populate(:name)[:name] rescue nil
        @service.service_user_name = @facebook_session.user.name rescue @service.service_user_name
        @service.service_user_name = session[:facebook_user_name] if session[:facebook_user_authorized]
        @service.save
      end
    end
    @facebook_session ||= Facebooker::Session.create
    @service = UserService.find_by_service_user_id_and_service(@facebook_user_id, 'facebook') if @facebook_user_id
    @user = @service.user if @service
    true
  end
end
