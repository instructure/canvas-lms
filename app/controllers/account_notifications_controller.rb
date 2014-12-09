#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
#           "example": "[\"information\"]",
#           "type": "array",
#           "items": {"type": "string"},
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
#           "example": "[\"StudentEnrollment\"]",
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "role_ids": {
#           "description": "The roles to send the notification to.  If roles is not passed it defaults to all roles",
#           "example": "[1]",
#           "type": "array",
#           "items": {"type": "integer"}
#         }
#       }
#     }
class AccountNotificationsController < ApplicationController
  include Api::V1::AccountNotifications
  before_filter :require_user
  before_filter :require_account_admin, except: [:user_index, :user_close_notification]

  # @API Index of active global notification for the user
  # Returns a list of all global notifications in the account for this user
  # Any notifications that have been closed by the user will not be returned
  #
  # @example_request
  #   curl -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/2/users/4/account_notifications
  #
  # @returns [AccountNotification]
  def user_index
    notifications = AccountNotification.for_user_and_account(@current_user, @domain_root_account)
    render :json => account_notifications_json(notifications, @current_user, session)
  end

  # @API Close notification for user
  # If the user no long wants to see this notification it can be excused with this call
  #
  # @example_request
  #   curl -X DELETE -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/2/users/4/account_notifications/4
  #
  # @returns AccountNotification
  def user_close_notification
    notification = AccountNotification.find(params[:id])
    @current_user.close_announcement(notification)
    render :json => account_notification_json(notification, @current_user, session)
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
    @notification = AccountNotification.new(params[:account_notification])
    @notification.account = @account
    @notification.user = @current_user
    unless params[:account_notification_roles].nil?
      roles = []

      params[:account_notification_roles].each do |role_param|
        if (role = @account.get_role_by_id(role_param)) && role.account_role?
          roles << role
        elsif role = @account.get_account_role_by_name(role_param)
          roles << role
        elsif role_param.nil? || role_param.to_s == "NilEnrollment"
          roles << nil
        end
      end

      @notification.account_notification_roles.build(roles.map{|role| {:role => role}})
    end
    respond_to do |format|
      if @notification.save
        if api_request?
          format.json { render :json => account_notification_json(@notification, @current_user, session) }
        else
          flash[:notice] = t(:announcement_created_notice, "Announcement successfully created")
          format.html { redirect_to account_settings_path(@account, :anchor => 'tab-announcements') }
          format.json { render :json => @notification }
        end
      else
        flash[:error] = t(:announcement_creation_failed_notice, "Announcement creation failed")
        format.html { redirect_to account_settings_path(@account, :anchor => 'tab-announcements') } unless api_request?
        format.json { render :json => @notification.errors, :status => :bad_request }
      end
    end
  end

  def destroy
    @notification = @account.announcements.find(params[:id])
    @notification.destroy
    respond_to do |format|
      flash[:message] = t(:announcement_deleted_notice, "Announcement successfully deleted")
      format.html { redirect_to account_settings_path(@account, :anchor => 'tab-announcements') }
      format.json { render :json => @notification }
    end
  end

  protected
  def require_account_admin
    get_context
    if !@account || @account.parent_account_id
      flash[:notice] = t(:permission_denied_notice, "You cannot create announcements for that account")
      redirect_to account_settings_path(params[:account_id])
      return false
    end
    return false unless authorized_action(@account, @current_user, :manage_alerts)
  end

end
