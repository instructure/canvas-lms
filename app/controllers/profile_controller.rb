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

# @API Users
class ProfileController < ApplicationController
  before_filter :require_user
  before_filter :reject_student_view_student
  before_filter { |c| c.active_tab = "profile" }

  include Api::V1::User

  # @API
  # Returns user profile data, including user id, name, and profile pic.
  #
  # When requesting the profile for the user accessing the API, the user's
  # calendar feed URL will be returned as well.
  #
  # @example_response
  #
  #   {
  #     'id': 1234,
  #     'name': 'Sample User',
  #     'sortable_name': 'user, sample',
  #     'email': 'sample_user@example.com',
  #     'login_id': 'sample_user@example.com',
  #     'sis_user_id': 'sis1',
  #     'sis_login_id': 'sis1-login',
  #     'avatar_url': '..url..',
  #     'calendar': { 'ics' => '..url..' }
  #   }
  def show
    if api_request?
      # allow querying this basic profile data for the current user, or any
      # user the current user has view_statistics access to
      @user = api_find(User, params[:user_id])
      return unless @user == @current_user || authorized_action(@user, @current_user, :view_statistics)
    else
      @user = @current_user
    end
    @channels = @user.communication_channels.unretired
    @email_channels = @channels.select{|c| c.path_type == "email"}
    @sms_channels = @channels.select{|c| c.path_type == 'sms'}
    @other_channels = @channels.select{|c| c.path_type != "email"}
    @default_email_channel = @email_channels.first
    @default_pseudonym = @user.primary_pseudonym
    @pseudonyms = @user.pseudonyms.active
    @password_pseudonyms = @pseudonyms.select{|p| !p.managed_password? }
    @context = UserProfile.new(@user)
    respond_to do |format|
      format.html do
        add_crumb(t(:crumb, "%{user}'s profile", :user => @user.short_name), profile_path )
        render :action => "profile"
      end
      format.json do
        hash = user_json(@user, @current_user, session, 'avatar_url')
        hash[:primary_email] = @default_email_channel.try(:path)
        hash[:login_id] ||= @default_pseudonym.try(:unique_id)
        if @user == @current_user
          hash[:calendar] = { :ics => "#{feeds_calendar_url(@user.feed_code)}.ics" }
        end
        render :json => hash
      end
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

    add_crumb(@user.short_name, profile_path )
    add_crumb(t(:crumb_notification_preferences, "Notification Preferences"), communication_profile_path )

    if @user.communication_channel.blank?
      flash[:error] = t('errors.no_channels', "Please define at least one email address or other way to be contacted before setting notification preferences.")
      redirect_to profile_url
      return
    end

    # Add communication channel for users that already had Twitter
    # integrated before we started offering it as a cc
    twitter_service = @user.user_services.find_by_service('twitter')
    twitter_service.assert_communication_channel if twitter_service
    @default_pseudonym = @user.primary_pseudonym
    @pseudonyms = @user.pseudonyms.active
    @channels = @user.communication_channels.unretired
    @current_user.used_feature(:cc_prefs)
    @notification_categories = Notification.dashboard_categories(@user)
    @policies = NotificationPolicy.for(@user).scoped(:include => [:communication_channel, :notification]).to_a
    @context = UserProfile.new(@user)
    @active_tab = "communication-preferences"

    # build placeholder notification policies for categories the user does not have policies for already
    # Note that currently a NotificationPolicy might not have a Notification attached to it.
    # See the relevant spec in profile_controller_spec.rb for more details.
    user_categories = @policies.map {|np| np.notification.try(:category) }
    @notification_categories.each do |category|
      # category is actually a Notification
      next if user_categories.include?(category.category)
      policy = @user.communication_channel.notification_policies.build
      policy.notification = category
      policy.frequency = category.default_frequency
      policy.save!
      @policies << policy
    end

    has_facebook_installed = !@current_user.user_services.for_service('facebook').empty?
    has_twitter_installed = !@current_user.user_services.for_service('twitter').empty?
    @email_channels = @channels.select{|c| c.path_type == "email"}
    @sms_channels = @channels.select{|c| c.path_type == 'sms'}
    @other_channels = @channels.select{|c| c.path_type != "email"}
    @other_channels.reject! { |c| c.path_type == 'facebook' } unless has_facebook_installed
    @other_channels.reject! { |c| c.path_type == 'twitter' } unless has_twitter_installed
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
          :url => data['profile_image_url_https'],
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
      :url => @current_user.gravatar_url(50, "/images/dotted_pic.png", request),
      :type => 'gravatar',
      :alt => 'gravatar pic'
    }
    @pics << {
      :url => '/images/dotted_pic.png',
      :type => 'none',
      :alt => 'no pic'
    }
    @current_user.profile_pics_folder.active_file_attachments({:include => :thumbnail}).select{|a| a.content_type.match(/\Aimage\//) && a.thumbnail}.sort_by(&:id).reverse.each do |image|
      @pics << {
        :url => "/images/thumbnails/#{image.id}/#{image.uuid}",
        :pending => image.thumbnail.nil?,
        :type => 'attachment',
        :alt => image.display_name
      }
    end
    render :json => @pics.to_json
  end
  
  def update
    @user = @current_user
    respond_to do |format|
      if !@user.user_can_edit_name? && params[:user]
        params[:user].delete(:name)
        params[:user].delete(:short_name)
        params[:user].delete(:sortable_name)
      end
      if @user.update_attributes(params[:user])
        pseudonymed = false
        if params[:default_email_id].present?
          @email_channel = @user.communication_channels.email.find_by_id(params[:default_email_id])
          @email_channel.move_to_top if @email_channel
        end
        if params[:pseudonym]
          change_password = params[:pseudonym].delete :change_password
          old_password = params[:pseudonym].delete :old_password
          pseudonym_to_update = @user.pseudonyms.find(params[:pseudonym][:password_id]) if params[:pseudonym][:password_id] && change_password
          if change_password == '1' && pseudonym_to_update && !pseudonym_to_update.valid_arbitrary_credentials?(old_password)
            pseudonymed = true
            flash[:error] = t('errors.invalid_old_password', "Invalid old password for the login %{pseudonym}", :pseudonym => pseudonym_to_update.unique_id)
            format.html { redirect_to profile_url }
            format.json { render :json => pseudonym_to_update.errors.to_json, :status => :bad_request }
          end
          if change_password != '1' || !pseudonym_to_update || !pseudonym_to_update.valid_arbitrary_credentials?(old_password)
            params[:pseudonym].delete :password
            params[:pseudonym].delete :password_confirmation
          end
          params[:pseudonym].delete :password_id
          if !params[:pseudonym].empty? && pseudonym_to_update && !pseudonym_to_update.update_attributes(params[:pseudonym])
            pseudonymed = true
            flash[:error] = t('errors.profile_update_failed', "Login failed to update")
            format.html { redirect_to profile_url }
            format.json { render :json => pseudonym_to_update.errors.to_json, :status => :bad_request }
          end
        end
        unless pseudonymed
          flash[:notice] = t('notices.updated_profile', "Profile successfully updated")
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
