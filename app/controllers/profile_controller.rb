# frozen_string_literal: true

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
#         "pronunciation": {
#           "description": "Name pronunciation",
#           "example": "Sample name pronunciation",
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
#         },
#         "k5_user": {
#           "description": "Optional: Whether or not the user is a K5 user. This field is nil if the user settings are not for the user making the request.",
#           "example": true,
#           "type": "boolean"
#         },
#         "use_classic_font_in_k5": {
#           "description": "Optional: Whether or not the user should see the classic font on the dashboard. Only applies if k5_user is true. This field is nil if the user settings are not for the user making the request.",
#           "example": false,
#           "type": "boolean"
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
  before_action :require_registered_user, except: %i[show settings communication communication_update]
  before_action :require_user, only: %i[settings communication communication_update qr_mobile_login]
  before_action :require_user_for_private_profile, only: :show
  before_action :reject_student_view_student
  before_action :require_password_session, only: %i[communication communication_update update]

  include HorizonMode
  before_action :load_canvas_career, only: %i[show settings communication content_shares qr_mobile_login]

  include Api::V1::Avatar
  include Api::V1::CommunicationChannel
  include Api::V1::NotificationPolicy
  include Api::V1::UserProfile

  include TextHelper
  include ProfileHelper
  include Login::OtpHelper

  def show
    unless @current_user && @domain_root_account.enable_profiles?
      return unless require_password_session

      settings
      return
    end

    @user ||= @current_user
    set_active_tab "profile"
    @context = @user.profile if @user == @current_user

    @user_data = profile_data(
      @user.profile,
      @current_user,
      session,
      ["links", "user_services"]
    )

    if @user_data[:known_user] # if you can message them, you can see the profile
      js_env enable_gravatar: @domain_root_account&.enable_gravatar?
      if @domain_root_account.try(:feature_enabled?, :instui_nav)
        add_crumb(@user.short_name, user_profile_path(@user))
        add_crumb(t("Profile"))
      else
        add_crumb(t("crumbs.settings_frd", "%{user}'s Profile", user: @user.short_name), user_profile_path(@user))
      end
      page_has_instui_topnav
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
    @channels = @user.communication_channels.unretired
    @pseudonyms = @user.pseudonyms_visible_to(@current_user).select(&:active?)
    @context = @user.profile
    set_active_tab "profile_settings"
    register_cc_tabs = ["email"]
    register_cc_tabs.push("sms") if current_mfa_settings != :disabled && otp_via_sms_in_us_region?
    register_cc_tabs.push("slack") if @user.account.feature_enabled?(:slack_notifications)
    is_default_account = @domain_root_account == Account.default
    can_update_tokens = @current_user.access_tokens.temp_record.grants_right?(logged_in_user, :update)
    google_drive_oauth_url = oauth_url(service: "google_drive", return_to: settings_profile_url)
    js_env({ enable_gravatar: @domain_root_account&.enable_gravatar?, register_cc_tabs:, is_default_account:, google_drive_oauth_url:, PERMISSIONS: { can_update_tokens: } })
    respond_to do |format|
      format.html do
        @user_data = profile_data(@user.profile, @current_user, session, [])
        @password_pseudonyms = @pseudonyms.reject(&:managed_password?)
        @email_channels = @channels.select { |c| c.path_type == "email" }
        @sms_channels = @channels.select { |c| c.path_type == "sms" }
        @other_channels = @channels.reject { |c| c.path_type == "email" }
        @default_email_channel = @email_channels.first
        @user.reload
        show_tutorial_ff_to_user = @domain_root_account&.feature_enabled?(:new_user_tutorial) &&
                                   @user.participating_instructor_course_ids.any?
        add_crumb(@user.short_name, profile_path)
        add_crumb(t("Settings"))
        js_env(
          NEW_USER_TUTORIALS_ENABLED_AT_ACCOUNT: show_tutorial_ff_to_user,
          CONTEXT_BASE_URL: "/users/#{@user.id}"
        )
        page_has_instui_topnav
        render :profile
      end
      format.json do
        render json: user_profile_json(@user.profile, @current_user, session, params[:include])
      end
    end
  end

  def communication
    @user = @current_user
    @current_user.used_feature(:cc_prefs)
    @context = @user.profile
    @page_title = t("account_notification_settings_title", "Notification Settings")
    set_active_tab "notifications"

    add_crumb(@current_user.short_name, profile_path)
    add_crumb(t("Notification Settings"))
    js_env NOTIFICATION_PREFERENCES_OPTIONS: {
      allowed_push_categories: Notification.categories_to_send_in_push,
      send_scores_in_emails_text: Notification.where(category: "Grading").first&.related_user_setting(@user, @domain_root_account),
      daily_notification_time: time_string(@current_user.daily_notification_time, nil, @current_user.time_zone || ActiveSupport::TimeZone["America/Denver"] || Time.zone),
      weekly_notification_range: {
        weekday: I18n.l(@current_user.weekly_notification_range.first.in_time_zone.to_date, format: :weekday),
        start_time: time_string(@current_user.weekly_notification_range.first, nil, @current_user.time_zone || ActiveSupport::TimeZone["America/Denver"] || Time.zone),
        end_time: time_string(@current_user.weekly_notification_range.last, nil, @current_user.time_zone || ActiveSupport::TimeZone["America/Denver"] || Time.zone)
      },
      read_privacy_info: @user.preferences[:read_notification_privacy_info],
      account_privacy_notice: @domain_root_account.settings[:external_notification_warning]
    }

    js_bundle :account_notification_settings
    respond_to do |format|
      format.html do
        page_has_instui_topnav
        render html: "", layout: true
      end
    end
  end

  def communication_update
    params[:root_account] = @domain_root_account
    NotificationPolicy.setup_for(@current_user, params)
    render json: {}, status: :ok
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
    @user = api_request? ? api_find(User, params[:user_id]) : @current_user
    if authorized_action(@user, @current_user, :update_avatar)
      render json: avatars_json_for_user(@user)
    end
  end

  def toggle_disable_inbox
    disable_inbox = value_to_boolean(params[:user][:disable_inbox])
    @current_user.preferences[:disable_inbox] = disable_inbox
    @current_user.save!

    email_channel_id = @current_user.email_channel.try(:id)
    if disable_inbox && !email_channel_id.nil?
      params = { channel_id: email_channel_id, frequency: "immediately" }

      ["added_to_conversation", "conversation_message"].each do |category|
        params[:category] = category
        NotificationPolicy.setup_for(@current_user, params)
      end
    end

    render json: {}
  end

  def admin?
    @domain_root_account.grants_right?(@current_user, :manage_courses_admin)
  end

  def allowed_to_change_pronouns?
    @domain_root_account.can_change_pronouns? || (@domain_root_account.can_add_pronouns? && admin?)
  end

  def update
    @user = @current_user

    if params[:privacy_notice].present?
      @user.preferences[:read_notification_privacy_info] = Time.now.utc.to_s
      @user.save

      return head :already_reported
    end

    respond_to do |format|
      user_params = if params[:user]
                      params[:user]
                        .permit(:name,
                                :short_name,
                                :sortable_name,
                                :time_zone,
                                :show_user_services,
                                :gender,
                                :avatar_image,
                                :subscribe_to_emails,
                                :locale,
                                :bio,
                                :birthdate,
                                :pronouns,
                                :pronunciation)
                    else
                      {}
                    end
      unless @user.user_can_edit_name?
        user_params.delete(:name)
        user_params.delete(:short_name)
        user_params.delete(:sortable_name)
      end

      is_invalid_pronoun = user_params[:pronouns].present? && @domain_root_account.pronouns.exclude?(user_params[:pronouns].strip)

      if !allowed_to_change_pronouns? || is_invalid_pronoun
        user_params.delete(:pronouns)
      end

      user_saved, pseudonymed = handle_profile_update(format, user_params)
      if user_saved
        unless pseudonymed
          flash[:notice] = t("notices.updated_profile", "Settings successfully updated") # rubocop:disable Rails/ActionControllerFlashBeforeRender
          format.html { redirect_to user_profile_url(@current_user) }
          format.json { render json: @user.as_json(methods: :avatar_url, include: { communication_channel: { only: [:id, :path], include_root: false }, pseudonym: { only: [:id, :unique_id], include_root: false } }) }
        end
      else
        format.html
        format.json { render json: @user.errors }
      end
    end
  end

  def handle_profile_update(format, user_params)
    pseudonymed = false
    user_updated = @user.update(user_params)
    if user_updated
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
        end
        if change_password == "1" && pseudonym_to_update && !pseudonym_to_update.valid_arbitrary_credentials?(old_password)
          error_msg = t("errors.invalid_old_passowrd", "Invalid old password for the login %{pseudonym}", pseudonym: pseudonym_to_update.unique_id)
          pseudonymed = true
          format.html do
            flash[:error] = error_msg
            redirect_to user_profile_url(@current_user)
          end
          format.json { render json: { errors: { old_password: error_msg } }, status: :bad_request }
        end
        if change_password != "1" || !pseudonym_to_update || !pseudonym_to_update.valid_arbitrary_credentials?(old_password)
          pseudonym_params.delete :password
          pseudonym_params.delete :password_confirmation
        end
        params[:pseudonym].delete :password_id
        pseudonym_to_update.require_password = true if pseudonym_to_update
        if !pseudonym_params.empty? && pseudonym_to_update && !pseudonym_to_update.update(pseudonym_params)
          pseudonymed = true
          flash[:error] = t("errors.profile_update_failed", "Login failed to update")
          format.html { redirect_to user_profile_url(@current_user) }
          format.json { render json: pseudonym_to_update.errors, status: :bad_request }
        end
      end
    end
    [user_updated, pseudonymed]
  end

  # TODO: the current update method needs to get moved to the UsersController
  # (since it is not concerned with profiles), then this should get renamed
  #
  # not doing API docs until we can move this to PUT /profile
  def update_profile
    @user = @current_user
    @profile = @user.profile
    @context = @profile

    if allowed_to_change_pronouns?
      valid_pronoun = @domain_root_account.pronouns.include?(params[:pronouns]&.strip) || params[:pronouns] == ""
      @user.pronouns = params[:pronouns] if valid_pronoun
    end

    short_name = params[:user] && params[:user][:short_name]
    @user.short_name = short_name if short_name && @user.user_can_edit_name?
    if params[:user_profile] && @user.user_can_edit_profile?
      user_profile_params = params[:user_profile].permit(:title, :pronunciation, :bio)
      user_profile_params.delete(:title) unless @user.user_can_edit_name?
      user_profile_params.delete(:pronunciation) unless @user.can_change_pronunciation?(@domain_root_account)
      @profile.attributes = user_profile_params
    end

    if params[:link_urls] && params[:link_titles] && @user.user_can_edit_profile?
      @profile.links = []
      params[:link_urls].zip(params[:link_titles])
                        .reject { |url, title| url.blank? && title.blank? }
                        .each do |url, title|
        new_link = @profile.links.build(url:, title:)
        # since every time we update links, we delete and recreate everything,
        # deleting invalid link records will make sure the rest of the
        # valid ones still save
        new_link.delete unless new_link.valid?
      end
    elsif params[:delete_links]
      @profile.links = []
    end

    if @user.valid? && @profile.valid?
      @user.save!
      @profile.save!
      flash[:success] = true

      if params[:user_services]
        visible, invisible = params[:user_services].to_unsafe_h.partition do |_service, bool|
          value_to_boolean(bool)
        end
        @user.user_services.where(service: visible.map(&:first)).update_all(visible: true)
        @user.user_services.where(service: invisible.map(&:first)).update_all(visible: false)
      end
      respond_to do |format|
        format.html { redirect_to user_profile_path(@user) }
        format.json { render json: user_profile_json(@user.profile, @current_user, session, params[:includes]) }
      end
    else
      flash[:success] = false
      respond_to do |format|
        format.html { redirect_to user_profile_path(@user) } # FIXME: need to go to edit path
        format.json { render json: @profile.errors, status: :bad_request } # NOTE: won't send back @user validation errors (i.e. short_name)
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
    @user ||= @current_user
    set_active_tab "observees"
    @context = @user.profile if @user == @current_user

    add_crumb(@user.short_name, profile_path)
    add_crumb(t("crumbs.observees", "Observing"))

    join_title(t(:page_title, "Students Being Observed"), @user.name)
    js_bundle :user_observees

    render html: "", layout: true
  end

  def content_shares
    return not_found unless @current_user.can_view_content_shares?

    @user ||= @current_user
    set_active_tab "content_shares"
    @context = @user.profile

    ccv_settings = DynamicSettings.find("common_cartridge_viewer") || {}
    js_env({
             COMMON_CARTRIDGE_VIEWER_URL: ccv_settings["base_url"]
           })
    render :content_shares
  end

  def qr_mobile_login
    unless instructure_misc_plugin_available? && !!@domain_root_account&.mobile_qr_login_is_enabled?
      head :not_found
      return
    end

    @user ||= @current_user
    set_active_tab "qr_mobile_login"
    @context = @user.profile if @user == @current_user

    add_crumb(@user.short_name, profile_path)
    add_crumb(t("crumbs.mobile_qr_login", "QR for Mobile Login"))

    page_has_instui_topnav
    render html: "", layout: true
  end
end

def instructure_misc_plugin_available?
  Object.const_defined?(:InstructureMiscPlugin)
end
private :instructure_misc_plugin_available?
