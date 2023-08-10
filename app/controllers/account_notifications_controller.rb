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

# @API Account Notifications
#
# API for account notifications.
# @model AccountNotification
#     {
#       "id": "AccountNotification",
#       "description": "",
#       "properties": {
#         "subject": {
#           "description": "The subject of the notifications",
#           "example": "Attention Students",
#           "type": "string"
#         },
#         "message": {
#           "description": "The message to be sent in the notification.",
#           "example": "This is a test of the notification system.",
#           "type": "string"
#         },
#         "start_at": {
#           "description": "When to send out the notification.",
#           "example": "2013-08-28T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "When to expire the notification.",
#           "example": "2013-08-29T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "icon": {
#           "description": "The icon to display with the message.  Defaults to warning.",
#           "example": "information",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "warning",
#               "information",
#               "question",
#               "error",
#               "calendar"
#             ]
#           }
#         },
#         "roles": {
#           "description": "(Deprecated) The roles to send the notification to.  If roles is not passed it defaults to all roles",
#           "example": ["StudentEnrollment"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "role_ids": {
#           "description": "The roles to send the notification to.  If roles is not passed it defaults to all roles",
#           "example": [1],
#           "type": "array",
#           "items": {"type": "integer"}
#         }
#       }
#     }
class AccountNotificationsController < ApplicationController
  include Api::V1::AccountNotifications
  before_action :require_user
  before_action :require_account_admin, only: %i[create update destroy]
  before_action :check_user_param, only: %i[user_index_deprecated user_close_notification_deprecated show_deprecated]

  # @API Index of active global notification for the user
  # Returns a list of all global notifications in the account for the current user
  # Any notifications that have been closed by the user will not be returned, unless
  # a include_past parameter is passed in as true.
  #
  # @argument include_past [Boolean]
  #   Include past and dismissed global announcements.
  #
  # @example_request
  #   curl -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/2/users/self/account_notifications
  #
  # @returns [AccountNotification]
  def user_index
    include_past = value_to_boolean(params[:include_past])
    notifications = AccountNotification.for_user_and_account(@current_user, @domain_root_account, include_past:)
    render json: account_notifications_json(notifications, @current_user, session)
  end

  def user_index_deprecated
    user_index
  end

  def render_past_global_announcements
    add_crumb(@current_user.short_name, profile_path)
    add_crumb(t("Global Announcements"))
    js_env(global_notifications: html_to_string)
    @show_left_side = true
    @context = @current_user.profile
    set_active_tab("past_global_announcements")
    js_bundle :past_global_announcements
    render html: "", layout: true
  end

  def html_to_string
    # This generates an array of html strings for the global announcements page
    # to allow for paination on the front end.
    html_strings = { current: [], past: [] }
    @for_display = true
    coll = AccountNotification.for_user_and_account(@current_user, @domain_root_account, include_past: true)
    [:current, :past].each do |time|
      coll.select(&time).in_groups_of(5, false) { |a| html_strings[time] << html_string_from_announcements(a) }
    end
    html_strings
  end

  def html_string_from_announcements(announcements)
    render_to_string(partial: "shared/account_notification", collection: announcements)
  end

  # @API Show a global notification
  # Returns a global notification for the current user
  # A notification that has been closed by the user will not be returned
  #
  # @example_request
  #   curl -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/2/users/self/account_notifications/4
  #
  # @returns AccountNotification
  def show
    notifications = AccountNotification.for_user_and_account(@current_user, @domain_root_account)
    notification = AccountNotification.find(params[:id])
    if notifications.include? notification
      render json: account_notification_json(notification, @current_user, session)
    else
      render_unauthorized_action
    end
  end

  def show_deprecated
    show
  end

  # @API Close notification for user
  # If the current user no long wants to see this notification it can be excused with this call
  #
  # @example_request
  #   curl -X DELETE -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/2/users/self/account_notifications/4
  #
  # @returns AccountNotification
  def user_close_notification
    notification = AccountNotification.find(params[:id])
    @current_user.close_announcement(notification)
    render json: account_notification_json(notification, @current_user, session)
  end

  def user_close_notification_deprecated
    user_close_notification
  end

  # @API Create a global notification
  # Create and return a new global notification for an account.
  #
  # @argument account_notification[subject] [Required, String]
  #  The subject of the notification.
  #
  # @argument account_notification[message] [Required, String]
  #  The message body of the notification.
  #
  # @argument account_notification[start_at] [Required, DateTime]
  #   The start date and time of the notification in ISO8601 format.
  #   e.g. 2014-01-01T01:00Z
  #
  # @argument account_notification[end_at] [Required, DateTime]
  #   The end date and time of the notification in ISO8601 format.
  #   e.g. 2014-01-01T01:00Z
  #
  # @argument account_notification[icon] ["warning"|"information"|"question"|"error"|"calendar"]
  #   The icon to display with the notification.
  #   Note: Defaults to warning.
  #
  # @argument account_notification_roles[] [String]
  #   The role(s) to send global notification to.  Note:  ommitting this field will send to everyone
  #   Example:
  #     account_notification_roles: ["StudentEnrollment", "TeacherEnrollment"]
  #
  # @example_request
  #   curl -X POST -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/2/account_notifications \
  #   -d 'account_notification[subject]=New notification' \
  #   -d 'account_notification[start_at]=2014-01-01T00:00:00Z' \
  #   -d 'account_notification[end_at]=2014-02-01T00:00:00Z' \
  #   -d 'account_notification[message]=This is a global notification'
  #
  # @example_response
  #   {
  #     "subject": "New notification",
  #     "start_at": "2014-01-01T00:00:00Z",
  #     "end_at": "2014-02-01T00:00:00Z",
  #     "message": "This is a global notification"
  #   }
  def create
    @notification = AccountNotification.new(account_notification_params)
    @notification.account = @account
    @notification.user = @current_user
    unless params[:account_notification_roles].nil?
      roles = []

      params[:account_notification_roles].each do |role_param|
        if (role = @account.get_role_by_id(role_param)) ||
           (role = @account.get_role_by_name(role_param))
          roles << role
        elsif role_param.nil? || role_param.to_s == "NilEnrollment"
          roles << nil
        end
      end

      @notification.account_notification_roles.build(roles.map { |role| { role: } })
    end
    respond_to do |format|
      if @notification.save
        if api_request?
          format.json { render json: account_notification_json(@notification, @current_user, session) }
        else
          flash[:notice] = t("Announcement successfully created")
          format.html { redirect_to account_settings_path(@account, anchor: "tab-announcements") }
          format.json { render json: @notification }
        end
      else
        flash[:error] = t("Announcement creation failed")
        format.html { redirect_to account_settings_path(@account, anchor: "tab-announcements") } unless api_request?
        format.json { render json: @notification.errors, status: :bad_request }
      end
    end
  end

  # @API Update a global notification
  #
  # Update global notification for an account.
  #
  # @argument account_notification[subject] [String]
  #  The subject of the notification.
  #
  # @argument account_notification[message] [String]
  #  The message body of the notification.
  #
  # @argument account_notification[start_at] [DateTime]
  #   The start date and time of the notification in ISO8601 format.
  #   e.g. 2014-01-01T01:00Z
  #
  # @argument account_notification[end_at] [DateTime]
  #   The end date and time of the notification in ISO8601 format.
  #   e.g. 2014-01-01T01:00Z
  #
  # @argument account_notification[icon] ["warning"|"information"|"question"|"error"|"calendar"]
  #   The icon to display with the notification.
  #
  # @argument account_notification_roles[] [String]
  #   The role(s) to send global notification to.  Note:  ommitting this field will send to everyone
  #   Example:
  #     account_notification_roles: ["StudentEnrollment", "TeacherEnrollment"]
  #
  # @example_request
  #   curl -X PUT -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/2/account_notifications/1 \
  #   -d 'account_notification[subject]=New notification' \
  #   -d 'account_notification[start_at]=2014-01-01T00:00:00Z' \
  #   -d 'account_notification[end_at]=2014-02-01T00:00:00Z' \
  #   -d 'account_notification[message]=This is a global notification'
  #
  # @example_response
  #   {
  #     "subject": "New notification",
  #     "start_at": "2014-01-01T00:00:00Z",
  #     "end_at": "2014-02-01T00:00:00Z",
  #     "message": "This is a global notification"
  #   }
  def update
    account_notification = @account.announcements.find(params[:id])
    if account_notification
      notification_params = params.require(:account_notification)
                                  .permit(:subject, :icon, :message, :start_at, :end_at, :required_account_service, :months_in_display_cycle, :domain_specific, :send_message)
      account_notification.attributes = notification_params

      if value_to_boolean(notification_params[:send_message])
        account_notification.messages_sent_at = nil # reset if we're explicitly re-sending messages
      end

      existing_roles = account_notification.account_notification_roles.map(&:role)
      requested_roles = roles_to_add(params[:account_notification_roles])
      new_roles = requested_roles - existing_roles
      remove_roles = existing_roles - requested_roles
      remove_roles_ids = remove_roles.map { |r| r.try(:id) }
      account_notification.account_notification_roles.create!(new_roles.map { |r| { role: r } })
      account_notification.account_notification_roles.where(role_id: remove_roles_ids).destroy_all if remove_roles.any?
      updated = account_notification.save
      respond_to do |format|
        if updated
          flash[:notice] = t("Announcement successfully updated")
          format.json { render json: account_notification_json(account_notification, @current_user, session) }
          format.html { redirect_to account_settings_path(@account, anchor: "tab-announcements") }
        else
          flash[:error] = t("Announcement update failed")
          format.html { redirect_to account_settings_path(@account, anchor: "tab-announcements") }
          format.json { render json: account_notification.errors, status: :bad_request }
        end
      end
    else
      respond_to do |format|
        flash[:error] = t("Announcement not found")
        format.html { redirect_to account_settings_path(@account, anchor: "tab-announcements") }
        format.json { render json: { message: "announcement not found" } }
      end
    end
  end

  def destroy
    @notification = @account.announcements.find(params[:id])
    @notification.destroy
    respond_to do |format|
      flash[:message] = t(:announcement_deleted_notice, "Announcement successfully deleted")
      format.html { redirect_to account_settings_path(@account, anchor: "tab-announcements") }
      format.json { render json: @notification }
    end
  end

  protected

  def check_user_param
    raise ActiveRecord::RecordNotFound unless api_find(User, params[:user_id]) == @current_user
  end

  def require_account_admin
    require_account_context
    false unless authorized_action(@account, @current_user, :manage_alerts)
  end

  def roles_to_add(role_params)
    roles = []
    return roles unless role_params

    role_params.each do |role_param|
      if role_param.nil? || role_param.to_s == "NilEnrollment"
        roles << nil
      else
        role = @account.get_role_by_id(role_param)
        role ||= @account.get_role_by_name(role_param)
        roles << role if role
      end
    end
    roles.uniq
  end

  def account_notification_params
    params.require(:account_notification)
          .permit(:subject, :icon, :message, :start_at, :end_at, :required_account_service, :months_in_display_cycle, :domain_specific, :send_message)
  end
end
