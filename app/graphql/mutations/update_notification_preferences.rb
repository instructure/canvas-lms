# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Types
  class NotificationFrequencyType < Types::BaseEnum
    graphql_name "NotificationFrequencyType"
    description "Frequency that notifications can be delivered on"
    value "immediately"
    value "daily"
    value "weekly"
    value "never"
  end

  class NotificationCategoryType < Types::BaseEnum
    graphql_name "NotificationCategoryType"
    description "The categories that a notification can belong to"
    Notification.valid_configurable_types.each do |type|
      value type
    end
  end
end

class Mutations::UpdateNotificationPreferences < Mutations::BaseMutation
  ValidationError = Class.new(StandardError)
  graphql_name "UpdateNotificationPreferences"

  argument :account_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Account")
  argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
  argument :context_type, Types::NotificationPreferencesContextType, required: true

  argument :enabled, Boolean, required: false
  argument :has_read_privacy_notice, Boolean, required: false
  argument :send_scores_in_emails, Boolean, required: false
  argument :send_observed_names_in_notifications, Boolean, required: false

  argument :communication_channel_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("CommunicationChannel")
  argument :notification_category, Types::NotificationCategoryType, required: false
  argument :frequency, Types::NotificationFrequencyType, required: false
  argument :is_policy_override, Boolean, required: false

  field :user, Types::UserType, null: true
  def resolve(input:)
    validate_input(input)
    context = get_context(input)

    unless input[:enabled].nil?
      NotificationPolicyOverride.enable_for_context(current_user, context, enable: input[:enabled])
    end

    if !input[:send_scores_in_emails].nil? && context.root_account.present? && context.root_account.settings[:allow_sending_scores_in_emails] != false
      if context.is_a?(Course)
        current_user.set_preference(:send_scores_in_emails_override, "course_" + context.global_id.to_s, input[:send_scores_in_emails])
      else
        current_user.preferences[:send_scores_in_emails] = input[:send_scores_in_emails]
        current_user.save!
      end
    end

    if input[:has_read_privacy_notice]
      current_user.preferences[:read_notification_privacy_info] = Time.now.utc.to_s
      current_user.save!
    end

    unless input[:send_observed_names_in_notifications].nil?
      current_user.preferences[:send_observed_names_in_notifications] = input[:send_observed_names_in_notifications]
      current_user.save!
    end

    # Because we validate the arguments for updating notification policies above we only need to
    # check for the presence of one of the arguments needed to update notification policies
    if input[:communication_channel_id]
      communication_channel = CommunicationChannel.find(input[:communication_channel_id])

      if communication_channel.user_id != current_user.id
        raise GraphQL::ExecutionError, "not found"
      end

      if input[:is_policy_override]
        NotificationPolicyOverride.create_or_update_for(communication_channel, input[:notification_category].tr("_", " "), input[:frequency], context)
      else
        NotificationPolicy.find_or_update_for_category(communication_channel, input[:notification_category].tr("_", " "), input[:frequency])
      end
    end

    {
      user: current_user
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue ::Mutations::UpdateNotificationPreferences::ValidationError => e
    validation_error(e.message)
  end

  def validate_input(input)
    err_klass = ::Mutations::UpdateNotificationPreferences::ValidationError
    if input[:context_type] == "Course" && !input[:course_id]
      raise err_klass, I18n.t("Course level notification preferences require a course_id to update")
    elsif input[:context_type] == "Account" && !input[:account_id]
      raise err_klass, I18n.t("Account level notification preferences require an account_id to update")
    end

    validate_policy_update_input(input)
  end

  def validate_policy_update_input(input)
    policy_update_input = [
      input[:communication_channel_id],
      input[:notification_category],
      input[:frequency]
    ]
    # We require that the 4 arguments listed above be present in order
    # to update notification policies or policy overrides
    if !policy_update_input.all? && policy_update_input.any?
      err_klass = ::Mutations::UpdateNotificationPreferences::ValidationError
      raise err_klass, I18n.t("Notification policies requires the communication channel id, the notification category, and the frequency to update")
    end
  end

  def get_context(input)
    case input[:context_type]
    when "Course"
      Course.find(input[:course_id]) if input[:course_id]
    when "Account"
      Account.find(input[:account_id]) if input[:account_id]
    end
  end
end
