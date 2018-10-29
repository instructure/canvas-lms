#
# Copyright (C) 2011 - present Instructure, Inc.
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
#
# @model Profile
#     {
#       "id": "Profile",
#       "description": "Profile details for a Canvas user.",
#       "properties": {
#         "id": {
#           "description": "The ID of the user.",
#           "example": 1234,
#           "type": "integer"
#         },
#         "name": {
#           "description": "Sample User",
#           "example": "Sample User",
#           "type": "string"
#         },
#         "short_name": {
#           "description": "Sample User",
#           "example": "Sample User",
#           "type": "string"
#         },
#         "sortable_name": {
#           "description": "user, sample",
#           "example": "user, sample",
#           "type": "string"
#         },
#         "title": {
#           "type": "string"
#         },
#         "bio": {
#           "type": "string"
#         },
#         "primary_email": {
#           "description": "sample_user@example.com",
#           "example": "sample_user@example.com",
#           "type": "string"
#         },
#         "login_id": {
#           "description": "sample_user@example.com",
#           "example": "sample_user@example.com",
#           "type": "string"
#         },
#         "sis_user_id": {
#           "description": "sis1",
#           "example": "sis1",
#           "type": "string"
#         },
#         "lti_user_id": {
#           "type": "string"
#         },
#         "avatar_url": {
#           "description": "The avatar_url can change over time, so we recommend not caching it for more than a few hours",
#           "example": "..url..",
#           "type": "string"
#         },
#         "calendar": {
#           "$ref": "CalendarLink"
#         },
#         "time_zone": {
#           "description": "Optional: This field is only returned in certain API calls, and will return the IANA time zone name of the user's preferred timezone.",
#           "example": "America/Denver",
#           "type": "string"
#         },
#         "locale": {
#           "description": "The users locale.",
#           "type": "string"
#         }
#       }
#     }
#
# @model Avatar
#     {
#       "id": "Avatar",
#       "description": "Possible avatar for a user.",
#       "required": ["type", "url", "token", "display_name"],
#       "properties": {
#         "type": {
#           "description": "['gravatar'|'attachment'|'no_pic'] The type of avatar record, for categorization purposes.",
#           "example": "gravatar",
#           "type": "string"
#         },
#         "url": {
#           "description": "The url of the avatar",
#           "example": "https://secure.gravatar.com/avatar/2284...",
#           "type": "string"
#         },
#         "token": {
#           "description": "A unique representation of the avatar record which can be used to set the avatar with the user update endpoint. Note: this is an internal representation and is subject to change without notice. It should be consumed with this api endpoint and used in the user update endpoint, and should not be constructed by the client.",
#           "example": "<opaque_token>",
#           "type": "string"
#         },
#         "display_name": {
#           "description": "A textual description of the avatar record.",
#           "example": "user, sample",
#           "type": "string"
#         },
#         "id": {
#           "description": "['attachment' type only] the internal id of the attachment",
#           "example": 12,
#           "type": "integer"
#         },
#         "content-type": {
#           "description": "['attachment' type only] the content-type of the attachment.",
#           "example": "image/jpeg",
#           "type": "string"
#         },
#         "filename": {
#           "description": "['attachment' type only] the filename of the attachment",
#           "example": "profile.jpg",
#           "type": "string"
#         },
#         "size": {
#           "description": "['attachment' type only] the size of the attachment",
#           "example": 32649,
#           "type": "integer"
#         }
#       }
#     }
#
class ProfileController < ApplicationController
  before_action :require_registered_user, :except => [:show, :settings, :communication, :communication_update]
  before_action :require_user, :only => [:settings, :communication, :communication_update]
  before_action :require_user_for_private_profile, :only => :show
  before_action :reject_student_view_student
  before_action :require_password_session, :only => [:communication, :communication_update, :update]

  include Api::V1::Avatar
  include Api::V1::CommunicationChannel
  include Api::V1::NotificationPolicy
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

    if @user_data[:known_user] # if you can message them, you can see the profile
      js_env :enable_gravatar => @domain_root_account&.enable_gravatar?
      add_crumb(t('crumbs.settings_frd', "%{user}'s Profile", :user => @user.short_name), user_profile_path(@user))
      render
    else
      render :unauthorized
    end
  end

  # @API Get user profile
  # Returns user profile data, including user id, name, and profile pic.
  #
  # When requesting the profile for the user accessing the API, the user's
  # calendar feed URL and LTI user id will be returned as well.
  #
  # @returns Profile
  def settings
    if api_request?
      @user = api_find(User, params[:user_id])
      return unless authorized_action(@user, @current_user, :read_profile)
    else
      return unless require_password_session
      @user = @current_user
      @user.dismiss_bouncing_channel_message!
    end
    @user_data = profile_data(@user.profile, @current_user, session, [])
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
    js_env :enable_gravatar => @domain_root_account&.enable_gravatar?
    respond_to do |format|
      format.html do
        show_tutorial_ff_to_user = @domain_root_account&.feature_enabled?(:new_user_tutorial) &&
                                   @user.participating_instructor_course_ids.any?
        add_crumb(t(:crumb, "%{user}'s settings", :user => @user.short_name), settings_profile_path )
        js_env(:NEW_USER_TUTORIALS_ENABLED_AT_ACCOUNT => show_tutorial_ff_to_user)
        render :profile
      end
      format.json do
        render :json => user_profile_json(@user.profile, @current_user, session, params[:include])
      end
    end
  end

  def communication
    @user = @current_user
    @current_user.used_feature(:cc_prefs)
    @context = @user.profile
    @active_tab = 'notifications'


    # Get the list of Notification models (that are treated like categories) that make up the full list of Categories.
    full_category_list = Notification.dashboard_categories(@user)
    categories = full_category_list.map do |category|
      category.as_json(only: %w{id name workflow_state user_id}, include_root: false).tap do |json|
        # Add custom method result entries to the json
        json[:category]             = category.category.underscore.gsub(/\s/, '_')
        json[:display_name]         = category.category_display_name
        json[:category_description] = category.category_description
        json[:option]               = category.related_user_setting(@user, @domain_root_account)
      end
    end

    js_env  :NOTIFICATION_PREFERENCES_OPTIONS => {
      :channels => @user.communication_channels.all_ordered_for_display(@user).map { |c| communication_channel_json(c, @user, session) },
      :policies => NotificationPolicy.setup_with_default_policies(@user, full_category_list).map { |p| notification_policy_json(p, @user, session).tap { |json| json[:communication_channel_id] = p.communication_channel_id } },
      :categories => categories,
      :update_url => communication_update_profile_path,
      :show_observed_names => @user.observer_enrollments.any? || @user.as_observer_observation_links.any? ? @user.send_observed_names_in_notifications? : nil
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
  # A paginated list of the possible user avatar options that can be set with the user update endpoint. The response will be an array of avatar records. If the 'type' field is 'attachment', the record will include all the normal attachment json fields; otherwise it will include only the 'url' and 'display_name' fields. Additionally, all records will include a 'type' field and a 'token' field. The following explains each field in more detail
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
  #   curl 'https://<canvas>/api/v1/users/1/avatars.json' \
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
  #       "url":<url to fetch thumbnail of attachment>,
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
  # @returns [Avatar]
  def profile_pics
    @user = if api_request? then api_find(User, params[:user_id]) else @current_user end
    if authorized_action(@user, @current_user, :update_avatar)
      render :json => avatars_json_for_user(@user)
    end
  end

  def toggle_disable_inbox
    disable_inbox = value_to_boolean(params[:user][:disable_inbox])
    @current_user.preferences[:disable_inbox] = disable_inbox
    @current_user.save!

    email_channel_id = @current_user.email_channel.try(:id)
    if disable_inbox && !email_channel_id.nil?
      params = {:channel_id=>email_channel_id,:frequency=>"immediately"}

      ["added_to_conversation", "conversation_message"].each do |category|
        params[:category] = category
        NotificationPolicy.setup_for(@current_user, params)
      end
    end

    render :json => {}
  end

  def update
    @user = @current_user

    if params[:privacy_notice].present?
      @user.preferences[:read_notification_privacy_info] = Time.now.utc.to_s
      @user.save

      return head 208
    end

    respond_to do |format|
      user_params = params[:user] ? params[:user].
        permit(:name, :short_name, :sortable_name, :time_zone, :show_user_services, :gender,
          :avatar_image, :subscribe_to_emails, :locale, :bio, :birthdate)
        : {}
      if !@user.user_can_edit_name?
        user_params.delete(:name)
        user_params.delete(:short_name)
        user_params.delete(:sortable_name)
      end
      if @user.update_attributes(user_params)
        pseudonymed = false
        if params[:default_email_id].present?
          @email_channel = @user.communication_channels.email.active.where(id: params[:default_email_id]).first
          if @email_channel
            @email_channel.move_to_top
            @user.clear_email_cache!
          end
        end
        if params[:pseudonym]
          pseudonym_params = params[:pseudonym].permit(:password, :password_confirmation, :unique_id)

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
            format.json { render :json => {:errors => {:old_password => error_msg}}, :status => :bad_request }
          end
          if change_password != '1' || !pseudonym_to_update || !pseudonym_to_update.valid_arbitrary_credentials?(old_password)
            pseudonym_params.delete :password
            pseudonym_params.delete :password_confirmation
          end
          params[:pseudonym].delete :password_id
          if !pseudonym_params.empty? && pseudonym_to_update && !pseudonym_to_update.update_attributes(pseudonym_params)
            pseudonymed = true
            flash[:error] = t('errors.profile_update_failed', "Login failed to update")
            format.html { redirect_to user_profile_url(@current_user) }
            format.json { render :json => pseudonym_to_update.errors, :status => :bad_request }
          end
        end
        unless pseudonymed
          flash[:notice] = t('notices.updated_profile', "Settings successfully updated")
          format.html { redirect_to user_profile_url(@current_user) }
          format.json { render :json => @user.as_json(:methods => :avatar_url, :include => {:communication_channel => {:only => [:id, :path], :include_root => false}, :pseudonym => {:only => [:id, :unique_id], :include_root => false} }) }
        end
      else
        format.html
        format.json { render :json => @user.errors }
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
    @user.short_name = short_name if short_name && @user.user_can_edit_name?
    if params[:user_profile]
      user_profile_params = params[:user_profile].permit(:title, :bio)
      user_profile_params.delete(:title) unless @user.user_can_edit_name?
      @profile.attributes = user_profile_params
    end

    if params[:link_urls] && params[:link_titles]
      @profile.links = []
      params[:link_urls].zip(params[:link_titles]).
        reject { |url, title| url.blank? && title.blank? }.
        each { |url, title|
          @profile.links.build :url => url, :title => title
        }
    elsif params[:delete_links]
      @profile.links = []
    end

    if @user.valid? && @profile.valid?
      @user.save!
      @profile.save!

      if params[:user_services]
        visible, invisible = params[:user_services].to_unsafe_h.partition { |service,bool|
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
        format.json { render :json => @profile.errors, :status => :bad_request }  #NOTE: won't send back @user validation errors (i.e. short_name)
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

  def observees
    if @domain_root_account.parent_registration?
      js_env(AUTH_TYPE: @domain_root_account.parent_auth_type)
    end
    @user ||= @current_user
    @active_tab = 'observees'
    @context = @user.profile if @user == @current_user

    add_crumb(@user.short_name, profile_path)
    add_crumb(t('crumbs.observees', "Observing"))
  end
end
