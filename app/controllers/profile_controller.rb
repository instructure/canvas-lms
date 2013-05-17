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
  before_filter :require_registered_user, :except => [:show, :settings, :communication, :communication_update]
  before_filter :require_user, :only => [:settings, :communication, :communication_update]
  before_filter :require_user_for_private_profile, :only => :show
  before_filter :reject_student_view_student
  before_filter :require_password_session, :only => [:settings, :communication, :communication_update, :update]

  include Api::V1::Avatar
  include Api::V1::Notification
  include Api::V1::NotificationPolicy
  include Api::V1::CommunicationChannel
  include Api::V1::UserProfile

  include TextHelper

  def show
    unless @current_user && @domain_root_account.enable_profiles?
      return unless require_password_session
      settings
      return
    end

    @user ||= @current_user
    @active_tab = "profile"
    @context = @user.profile if @user == @current_user

    @user_data = profile_data(
      @user.profile,
      @current_user,
      session,
      ['links', 'user_services']
    )

    known_user = @user_data[:common_contexts].present?
    if @user_data[:known_user] # if you can message them, you can see the profile
      add_crumb(t('crumbs.settings_frd', "%{user}'s settings", :user => @user.short_name), user_profile_path(@user))
      return render :action => :show
    else
      return render :action => :unauthorized
    end
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
  #     'short_name': 'Sample User'
  #     'sortable_name': 'user, sample',
  #     'primary_email': 'sample_user@example.com',
  #     'login_id': 'sample_user@example.com',
  #     'sis_user_id': 'sis1',
  #     'sis_login_id': 'sis1-login',
  #     // The avatar_url can change over time, so we recommend not caching it for more than a few hours
  #     'avatar_url': '..url..',
  #     'calendar': { 'ics' => '..url..' }
  #   }
  def settings
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
    @context = @user.profile
    @active_tab = "profile_settings"
    respond_to do |format|
      format.html do
        add_crumb(t(:crumb, "%{user}'s settings", :user => @user.short_name), settings_profile_path )
        render :action => "profile"
      end
      format.json do
        render :json => user_profile_json(@user.profile, @current_user, session, params[:include])
      end
    end
  end

  def communication
    @user = @current_user
    @user = User.find(params[:id]) if params[:id]
    @current_user.used_feature(:cc_prefs)
    @context = @user.profile
    @active_tab = 'notifications'

    # Get the list of Notification models (that are treated like categories) that make up the full list of Categories.
    full_category_list = Notification.dashboard_categories(@user)
    js_env  :NOTIFICATION_PREFERENCES_OPTIONS => {
      :channels => @user.communication_channels.all_ordered_for_display(@user).map { |c| communication_channel_json(c, @user, session) },
      :policies => NotificationPolicy.setup_with_default_policies(@user, full_category_list).map{ |p| notification_policy_json(p, @user, session) },
      :categories => full_category_list.map{ |c| notification_category_json(c, @user, session) },
      :update_url => communication_update_profile_path,
      },
      :READ_PRIVACY_INFO => @user.preferences[:read_notification_privacy_info],
      :ACCOUNT_PRIVACY_NOTICE => @domain_root_account.settings[:external_notification_warning]
  end

  def communication_update
    params[:root_account] = @domain_root_account
    NotificationPolicy.setup_for(@current_user, params)
    render :json => {}, :status => :ok
  end

  # @API List avatar options
  # Retrieve the possible user avatar options that can be set with the user update endpoint. The response will be an array of avatar records. If the 'type' field is 'attachment', the record will include all the normal attachment json fields; otherwise it will include only the 'url' and 'display_name' fields. Additionally, all records will include a 'type' field and a 'token' field. The following explains each field in more detail
  # type:: ["gravatar"|"attachment"|"no_pic"] The type of avatar record, for categorization purposes.
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

    if params[:privacy_notice].present?
      @user.preferences[:read_notification_privacy_info] = Time.now.utc.to_s
      @user.save

      return render(:nothing => true, :status => 208)
    end

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
          if params[:pseudonym][:password_id] && change_password
            pseudonym_to_update = @user.pseudonyms.find(params[:pseudonym][:password_id])
            pseudonym_to_update.require_password = true if pseudonym_to_update
          end
          if change_password == '1' && pseudonym_to_update && !pseudonym_to_update.valid_arbitrary_credentials?(old_password)
            error_msg = t('errors.invalid_old_passowrd', "Invalid old password for the login %{pseudonym}", :pseudonym => pseudonym_to_update.unique_id)
            pseudonymed = true
            flash[:error] = error_msg
            format.html { redirect_to user_profile_url(@current_user) }
            format.json { render :json => {:errors => {:old_password => error_msg}}.to_json, :status => :bad_request }
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
          flash[:notice] = t('notices.updated_profile', "Settings successfully updated")
          format.html { redirect_to user_profile_url(@current_user) }
          format.json { render :json => @user.to_json(:methods => :avatar_url, :include => {:communication_channel => {:only => [:id, :path]}, :pseudonym => {:only => [:id, :unique_id]} }) }
        end
      else
        format.html
        format.json { render :json => @user.errors.to_json }
      end
    end
  end

  # TODO: the current update method needs to get moved to the UsersController
  # (since it is not concerned with profiles), then this should get renamed
  #
  # not doing API docs until we can move this to PUT /profile
  def update_profile
    @user = @current_user
    @profile = @user.profile
    @context = @profile

    short_name = params[:user] && params[:user][:short_name]
    @user.short_name = short_name if short_name
    @profile.attributes = params[:user_profile]

    if params[:link_urls] && params[:link_titles]
      links = params[:link_urls].zip(params[:link_titles]).
        reject { |url, title| url.blank? && title.blank? }.
        map { |url, title|
          UserProfileLink.new :url => url, :title => title
        }
      @profile.links = links
    end

    if @user.valid? && @profile.valid?
      @user.save!
      @profile.save!

      if params[:user_services]
        visible, invisible = params[:user_services].partition { |service,bool|
          value_to_boolean(bool)
        }
        @user.user_services.where(:service => visible.map(&:first)).update_all(:visible => true)
        @user.user_services.where(:service => invisible.map(&:first)).update_all(:visible => false)
      end

      respond_to do |format|
        format.html { redirect_to user_profile_path(@user) }
        format.json { render :json => user_profile_json(@user.profile, @current_user, session, params[:includes]) }
      end
    else
      respond_to do |format|
        format.html { redirect_to user_profile_path(@user) } # FIXME: need to go to edit path
        format.json { render :json => 'TODO' }
      end
    end
  end

  def require_user_for_private_profile
    if params[:id]
      @user = api_find(User, params[:id])
      return if @user.public?
    end
    require_user
  end
  private :require_user_for_private_profile
end
