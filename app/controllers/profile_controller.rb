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
  before_filter :require_user, :except => :show
  before_filter :require_user_for_private_profile, :only => :show
  before_filter :reject_student_view_student

  include Api::V1::User
  include Api::V1::Avatar

  include TextHelper

  def show
    if @current_user && @domain_root_account.enable_profiles?
      # this is ghetto and we should get rid of this as soon as possible
      @current_user.instance_variable_set(:@show_profile_tab, true)
    else
      edit
      return
    end

    @user ||= @current_user

    @active_tab = "profile"
    @context = UserProfile.new(@current_user) if @user == @current_user

    js_env :USER_ID => @user.id

    @items_count = @user.collection_items.scoped(:conditions => {'collections.visibility' => 'public'}).count
    @followers_count = @user.following_user_follow_ids.count

    @following_user = @current_user &&
      UserFollow.followed_by_user([@user], @current_user).present?

    @can_follow = !@following_user &&
      @current_user &&
      @user.grants_right?(@current_user, :follow)

    @services = @user.user_services.where(
      :service => %w(facebook twitter linked_in delicious diigo skype)
    ).sort_by { |s| UserService.sort_position(s.service) }

    if @user.private? && @user != @current_user
      if @user.grants_right?(@current_user, :view_statistics)
        return render :action => :show
      elsif @current_user.messageable_users(:ids => [@user.id]) == [@user]
        return render :action => :show_limited
      # TODO: also show full profile if user is following other user?
      else
        return render :action => :unauthorized
      end
    end

    render :action => :show
  end

  # @API Get user profile
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
  def edit
    if @current_user && @domain_root_account.enable_profiles?
      @current_user.instance_variable_set(:@show_profile_tab, true)
    end

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
    @active_tab = "edit_profile"
    respond_to do |format|
      format.html do
        add_crumb(t(:crumb, "%{user}'s profile", :user => @user.short_name), edit_profile_path )
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

    add_crumb(@user.short_name, user_profile_path(@current_user) )
    add_crumb(t(:crumb_notification_preferences, "Notification Preferences"), communication_profile_path )

    if @user.communication_channel.blank?
      flash[:error] = t('errors.no_channels', "Please define at least one email address or other way to be contacted before setting notification preferences.")
      redirect_to user_profile_url(@current_user)
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
  
  # @API List avatar options
  # Retrieve the possible user avatar options that can be set with the user update endpoint. The response will be an array of avatar records. If the 'type' field is 'attachment', the record will include all the normal attachment json fields; otherwise it will include only the 'url' and 'display_name' fields. Additionally, all records will include a 'type' field and a 'token' field. The following explains each field in more detail
  # type:: ["gravatar"|"twitter"|"linked_in"|"attachment"|"no_pic"] The type of avatar record, for categorization purposes.
  # url:: The url of the avatar 
  # token:: A unique representation of the avatar record which can be used to set the avatar with the user update endpoint. Note: this is an internal representation and is subject to change without notice. It should be consumed with this api endpoint and used in the user update endpoint, and should not be constructed by the client.
  # display_name:: A textual description of the avatar record
  # id:: ['attachment' type only] the internal id of the attachment
  # content-type:: ['attachment' type only] the content-type of the attachment
  # filename:: ['attachment' type only] the filename of the attachment
  # size:: ['attachment' type only] the size of the attachment
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/users/1/avatars.json' \ 
  #        -H "Authorization: Bearer <token>"
  #
  # @example_response
  #
  #   [
  #     {
  #       "type":"gravatar",
  #       "url":"https://secure.gravatar.com/avatar/2284...",
  #       "token":<opaque_token>,
  #       "display_name":"gravatar pic"
  #     },
  #     {
  #       "type":"attachment",
  #       "url":"https://<canvas>/images/thumbnails/12/gpLWJ...",
  #       "token":<opaque_token>,
  #       "display_name":"profile.jpg",
  #       "id":12,
  #       "content-type":"image/jpeg",
  #       "filename":"profile.jpg",
  #       "size":32649
  #     },
  #     {
  #       "type":"no_pic",
  #       "url":"https://<canvas>/images/dotted_pic.png",
  #       "token":<opaque_token>,
  #       "display_name":"no pic"
  #     }
  #   ]
  def profile_pics
    @user = if api_request? then api_find(User, params[:user_id]) else @current_user end
    if authorized_action(@user, @current_user, :update_avatar)
      render :json => avatars_json_for_user(@user)
    end
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
            format.html { redirect_to user_profile_url(@current_user) }
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
            format.html { redirect_to user_profile_url(@current_user) }
            format.json { render :json => pseudonym_to_update.errors.to_json, :status => :bad_request }
          end
        end
        unless pseudonymed
          flash[:notice] = t('notices.updated_profile', "Profile successfully updated")
          format.html { redirect_to user_profile_url(@current_user) }
          format.json { render :json => @user.to_json(:methods => :avatar_url, :include => {:communication_channel => {:only => [:id, :path]}, :pseudonym => {:only => [:id, :unique_id]} }) }
        end
      else
        format.html
        format.json { render :json => @user.errors.to_json }
      end
    end
  end

  def require_user_for_private_profile
    if params[:id]
      @user = User.find(params[:id])
      return if @user.public?
    end
    require_user
  end
  private :require_user_for_private_profile
end
