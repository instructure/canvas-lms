# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

# @API Notification Preferences
#
# API for managing notification preferences
#
# @model NotificationPreference
#     {
#       "id": "NotificationPreference",
#       "description": "",
#       "properties": {
#         "href": {
#           "example": "https://canvas.instructure.com/users/1/communication_channels/email/student@example.edu/notification_preferences/new_announcement",
#           "type": "string"
#         },
#         "notification": {
#           "description": "The notification this preference belongs to",
#           "example": "new_announcement",
#           "type": "string"
#         },
#         "category": {
#           "description": "The category of that notification",
#           "example": "announcement",
#           "type": "string"
#         },
#         "frequency": {
#           "description": "How often to send notifications to this communication channel for the given notification. Possible values are 'immediately', 'daily', 'weekly', and 'never'",
#           "example": "daily",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "immediately",
#               "daily",
#               "weekly",
#               "never"
#             ]
#           }
#         }
#       }
#     }
#
class NotificationPreferencesController < ApplicationController
  before_action :require_user, :get_cc

  include Api::V1::NotificationPolicy

  # @API List preferences
  # Fetch all preferences for the given communication channel
  # @returns [NotificationPreference]
  def index
    policies = NotificationPolicy.find_all_for(@cc)
    render json: { notification_preferences: policies.map { |p| notification_policy_json(p, @current_user, session) } }
  end

  # @API List of preference categories
  # Fetch all notification preference categories for the given communication channel
  def category_index
    policies = NotificationPolicy.find_all_for(@cc)
    render json: { categories: policies.filter_map { |p| p.notification.try(:category_slug) }.uniq }
  end

  # @API Get a preference
  # Fetch the preference for the given notification for the given communication channel
  # @returns NotificationPreference
  def show
    render json: { notification_preferences: [notification_policy_json(NotificationPolicy.find_or_update_for(@cc, params[:notification]), @current_user, session)] }
  end

  # @API Update a preference
  # Change the preference for a single notification for a single communication channel
  # @argument notification_preferences[frequency] [Required] The desired frequency for this notification
  def update
    return render_unauthorized_action unless @user == @current_user

    preference = notification_preferences_param
    render json: { notification_preferences: [notification_policy_json(NotificationPolicy.find_or_update_for(@cc, params[:notification], preference[:frequency]), @current_user, session)] }
  end

  # @API Update preferences by category
  # Change the preferences for multiple notifications based on the category for a single communication channel
  # @argument category [String] The name of the category. Must be parameterized (e.g. The category "Course Content" should be "course_content")
  # @argument notification_preferences[frequency] [Required] The desired frequency for each notification in the category
  def update_preferences_by_category
    return render_unauthorized_action unless @user == @current_user

    preference = notification_preferences_param

    # Every other category is along the lines of `Due Date`, which is processed correctly by
    # titleize. Make `DiscussionEntry` not a special snowflake here.
    category = params[:category].casecmp?("discussionentry") ? "DiscussionEntry" : params[:category].titleize

    policies = NotificationPolicy.find_or_update_for_category(@cc, category, preference[:frequency])
    render json: { notification_preferences: policies.map { |p| notification_policy_json(p, @current_user, session) } }
  end

  # @API Update multiple preferences
  # Change the preferences for multiple notifications for a single communication channel at once
  # @argument notification_preferences[<X>][frequency] [Required] The desired frequency for <X> notification
  def update_all
    return render_unauthorized_action unless @user == @current_user

    preferences = convert_hash_to_jsonapi_array(params[:notification_preferences], :notification)
    policies = preferences.map do |preference|
      NotificationPolicy.find_or_update_for(@cc, preference[:notification], preference[:frequency])
    end
    render json: { notification_preferences: policies.map { |p| notification_policy_json(p, @current_user, session) } }
  end

  private

  def convert_hash_to_jsonapi_array(hash, key = :id)
    return hash if hash.is_a?(Array)

    hash.to_unsafe_h.map { |k, v| { key => k }.reverse_merge!(v).with_indifferent_access }
  end

  def notification_preferences_param
    # support both JSON API style (notification preferences is an array) and Canvas API style (it's a hash)
    notif_pref = params[:notification_preferences]
    notif_pref.is_a?(Array) ? notif_pref.first : notif_pref
  end

  def get_cc
    params[:user_id] ||= "self"
    @user = api_find(User, params[:user_id])
    if params[:communication_channel_id]
      @cc = @user.communication_channels.unretired.find(params[:communication_channel_id])
    else
      @cc = @user.communication_channels.unretired.of_type(params[:type]).by_path(params[:address]).first
      raise ActiveRecord::RecordNotFound unless @cc
    end
    return unless @user == @current_user || authorized_action(@user, @current_user, :view_statistics)

    @cc.user = @user
  end
end
