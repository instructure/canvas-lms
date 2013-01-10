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
  protect_from_forgery :only => []
  before_filter :get_facebook_user
  before_filter :require_facebook_user, :only => [:settings, :notification_preferences, :hide_message]
  filter_parameter_logging :fb_sig_friends
  
  def notification_preferences
    @cc = @user.communication_channels.find_by_path_type('facebook')
    if @cc
      @old_policies = @cc.notification_policies
      @policies = []
      params[:types].each do |type, frequency|
        notifications = Notification.find_all_by_category(type)
        notifications.each do |notification|
          pref = @cc.notification_policies.new
          pref.notification_id = notification.id
          pref.frequency = frequency
          @policies << pref unless frequency == 'never'
        end
      end
      NotificationPolicy.transaction do
        @old_policies.each{|p| p.destroy}
        @policies.each{|p| p.save!}
      end
    end
    # TODO: i18n... see notification.rb
    @notification_categories = Notification.dashboard_categories.reject{|c| c.category == "Summaries"}
    @policies = @cc.notification_policies
    redirect_to facebook_settings_url
  end
  
  def hide_message
    @message = @user.messages.to_facebook.find(params[:id])
    @message.destroy
    render :json => @message.to_json
  end
  
  def index
    if request.post?
      redirect_to facebook_url
      return
    end
    flash[:notice] = t :authorization_success, "Authorization successful!  Canvas and Facebook are now friends." if params[:just_authorized]
    @messages = []
    if @user
      @messages = @user.messages.to_facebook.to_a
      Facebook.dashboard_clear_count(@service) if @service
      @domains = @user.pseudonyms.scoped({:include => :account}).to_a.once_per(&:account_id).map{|p| HostUrl.context_host(p.account) }.uniq
    end
    respond_to do |format|
      format.html { render :action => 'index', :layout => 'facebook' }
    end
  end
  
  def settings
    @notification_categories = Notification.dashboard_categories
    @cc = @user && @user.communication_channels.find_by_path_type('facebook')
    @policies = @cc.try(:notification_policies)
    respond_to do |format|
      format.html { render :action => 'settings', :layout => 'facebook' }
    end
  end
  
  def remove_user
    @service.destroy if @service
    render :text => t(:deleted, "Deleted")
  end
  
  def facebook_disabled?
    if !feature_and_service_enabled?(:facebook) 
      respond_to do |format|
        format.fbml { render :action => 'index_disabled', :layout => 'facebook' }
      end
      return true
    end
  end
  
  protected
  def require_facebook_user
    if !@user
      flash[:error] = t :authorization_required, "Only authorized users can access that page"
      redirect_to facebook_url
    end
  end

  def get_facebook_user
    return false if facebook_disabled?
    @embeddable = true

    if params[:signed_request]
      data, sig = Facebook.parse_signed_request(params[:signed_request])
      if data && sig
        if @facebook_user_id = data['user_id']
          Shard.with_each_shard do
            @service = UserService.find_by_service_and_service_user_id('facebook', @facebook_user_id)
            break if @service
          end
        end
        if @service
          @service.update_attribute(:token, data['oauth_token']) if !@service.token && data['oauth_token']
          @user = @service.user
        end
        session[:facebook_canvas_user_id] = @user.id if @user
        return true
      else
        flash[:error] = t :invalid_signature, "Invalid Facebook signature"
        redirect_to dashboard_url
        return false
      end
    elsif session[:facebook_canvas_user_id]
      @user = User.find(session[:facebook_canvas_user_id])
      @service = @user.user_services.find_by_service('facebook')
    elsif session[:facebook_user_id]
      @facebook_user_id = session[:facebook_user_id]
      Shard.with_each_shard do
        @service = UserService.find_by_service_and_service_user_id('facebook', @facebook_user_id)
        break if @service
      end
      @user = @service && @service.user
      session[:facebook_canvas_user_id] = @user.id if @user
    elsif params[:force_view] == '1'
      if @current_user
        @user = @current_user
        session[:facebook_canvas_user_id] = @user.id
        @service = @user.user_services.find_by_service('facebook')
      end
    end
  end
end
