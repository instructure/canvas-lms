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

class ProfileController < ApplicationController
  before_filter :require_user
  before_filter { |c| c.active_tab = "profile" }
  
  def show
    @user = params[:id] ? User.find(params[:id]) : @current_user
    add_crumb("#{@user.short_name}'s profile", profile_path )
    @channels = @user.communication_channels.unretired
    @email_channels = @channels.select{|c| c.path_type == "email"}
    @sms_channels = @channels.select{|c| c.path_type == 'sms'}
    @other_channels = @channels.select{|c| c.path_type != "email"}
    @default_email_channel = @email_channels.first
    @default_pseudonym = @user.primary_pseudonym
    @pseudonyms = @user.pseudonyms.active
    @password_pseudonyms = @pseudonyms.select{|p| !p.managed_password? }
    @courses = @user.courses
    @context = UserProfile.new(@user)
    respond_to do |format|
      format.html { render :action => "profile" }
      format.xml  { render :xml => @user.to_xml }
    end
  end
  
  def update_communication
    params[:root_account] = @domain_root_account
    @policies = NotificationPolicy.setup_for(@current_user, params)
    render :json => @policies.to_json
  end
  
  def communication
    @user = @current_user
    @user = User.find(params[:id]) if params[:id]

    if @user.communication_channel.blank?
      flash[:error] = "Please define at least one email address or other way to be contacted before setting notification preferences."
      redirect_to profile_url
      return
    end

    @default_pseudonym = @user.primary_pseudonym
    @pseudonyms = @user.pseudonyms.active
    @channels = @user.communication_channels.unretired
    @current_user.used_feature(:cc_prefs)
    @notification_categories = Notification.dashboard_categories(@user)
    @policies = @user.notification_policies
    @context = UserProfile.new(@user)
    @active_tab = "communication-preferences"
    if @policies.empty?
      @notification_categories.each do |category|
        policy = @user.notification_policies.build
        policy.notification = category
        policy.communication_channel = @user.communication_channel
        @policies << policy
      end
    end
    has_facebook_installed = !@current_user.user_services.for_service('facebook').empty?
    @policies = @policies.select{|p| (p.communication_channel && p.communication_channel.path_type != 'facebook') || has_facebook_installed }
    @email_channels = @channels.select{|c| c.path_type == "email"}
    @sms_channels = @channels.select{|c| c.path_type == 'sms'}
    @other_channels = @channels.select{|c| c.path_type != "email"}
  end
  
  def profile_pics
    @pics = []
    @user = @current_user
    if feature_enabled?(:facebook) && facebook = @user.facebook
      # TODO: add facebook picture if enabled
    end
    if feature_enabled?(:twitter) && twitter = @user.user_services.for_service('twitter').first
      url = URI.parse("http://twitter.com/users/show.json?user_id=#{twitter.service_user_id}")
      data = JSON.parse(Net::HTTP.get(url)) rescue nil
      if data
        @pics << {
          :url => data['profile_image_url'],
          :type => 'twitter',
          :alt => 'twitter pic'
        }
      end
    end
    if feature_enabled?(:linked_in) && linked_in = @user.user_services.for_service('linked_in').first
      self.extend LinkedIn
      profile = linked_in_profile
      if profile && profile['picture_url']
        @pics << {
          :url => profile['picture_url'],
          :type => 'linked_in',
          :alt => 'linked_in pic'
        }
      end
    end
    @pics << {
      :url => @current_user.gravatar_url(50, "http://#{HostUrl.default_host}/images/dotted_pic.png"),
      :type => 'gravatar',
      :alt => 'gravatar pic'
    }
    @pics << {
      :url => '/images/dotted_pic.png',
      :type => 'none',
      :alt => 'no pic'
    }
    @current_user.attachments.scoped({:include => :thumbnail}).select{|a| a.content_type.match(/\Aimage\//) && a.thumbnail}.sort_by(&:id).reverse.each do |image|
      @pics << {
        :url => "/images/thumbnails/#{image.id}/#{image.uuid}",
        :type => 'attachment',
        :alt => image.display_name
      }
    end
    render :json => @pics.to_json
  end
  
  def update
    @user = @current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        pseudonymed = false
        if params[:default_email_id].present?
          @user.communication_channels.each_with_index{|cc, idx| cc.insert_at(idx + 1) }
          @email_channel = @user.communication_channels.find_by_id(params[:default_email_id])
          @email_channel.move_to_top if @email_channel
        end
        if params[:pseudonym]
          change_password = params[:pseudonym].delete :change_password
          old_password = params[:pseudonym].delete :old_password
          pseudonym_to_update = @user.pseudonyms.find(params[:pseudonym][:password_id]) if params[:pseudonym][:password_id] && change_password
          if change_password == '1' && pseudonym_to_update && !pseudonym_to_update.valid_password?(old_password)
            pseudonymed = true
            flash[:error] = "Invalid old password for the login #{pseudonym_to_update.unique_id}"
            format.html { redirect_to profile_url }
            format.json { render :json => pseudonym_to_update.errors.to_json, :status => :bad_request }
          end
          if change_password != '1' || !pseudonym_to_update || !pseudonym_to_update.valid_password?(old_password)
            params[:pseudonym].delete :password
            params[:pseudonym].delete :password_confirmation
          end
          params[:pseudonym].delete :password_id
          if !params[:pseudonym].empty? && pseudonym_to_update && !pseudonym_to_update.update_attributes(params[:pseudonym])
            pseudonymed = true
            flash[:error] = "Login failed to update"
            format.html { redirect_to profile_url }
            format.json { render :json => pseudonym_to_update.errors.to_json, :status => :bad_request }
          end
        end
        if params[:default_communication_channel_id].present?
          cc = @user.communication_channels.each_with_index{|cc, idx| cc.insert_at(idx + 1) }
          cc = @user.communication_channels.find_by_id_and_path_type(params[:default_communication_channel_id], 'email')
          cc.insert_at(1) if cc
        end
        unless pseudonymed
          flash[:notice] = "Profile successfully updated"
          format.html { redirect_to profile_url }
          format.json { render :json => @user.to_json(:methods => :avatar_url, :include => {:communication_channel => {:only => [:id, :path]}, :pseudonym => {:only => [:id, :unique_id]} }) }
        end
      else
        format.html
        format.json { render :json => @user.errors.to_json }
      end
    end
  end
end
