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

class NotificationPreferencesContextType < Types::BaseEnum
  graphql_name 'NotificationPreferencesContextType'
  description 'Context types that can be associated with notification preferences'
  value 'Course'
  value 'Account'
end

class NotificationFrequencyType < Types::BaseEnum
  graphql_name 'NotificationFrequencyType'
  description 'Frequency that notifications can be delivered on'
  value 'immediately'
  value 'daily'
  value 'weekly'
  value 'never'
end

class NotificationCategoryType < Types::BaseEnum
  graphql_name 'NotificationCategoryType'
  description 'The categories that a notification can belong to'
  value 'Account_Notification'
  value 'Added_To_Conversation'
  value 'All_Submissions'
  value 'Announcement'
  value 'Announcement_Created_By_You'
  value 'Appointment_Availability'
  value 'Appointment_Cancelations'
  value 'Appointment_Signups'
  value 'Blueprint'
  value 'Calendar'
  value 'Content_Link_Error'
  value 'Conversation_Created'
  value 'Conversation_Message'
  value 'Course_Content'
  value 'Discussion'
  value 'DiscussionEntry'
  value 'Due_Date'
  value 'Files'
  value 'Grading'
  value 'Grading_Policies'
  value 'Invitation'
  value 'Late_Grading'
  value 'Membership_Update'
  value 'Other'
  value 'Recording_Ready'
  value 'Student_Appointment_Signups'
  value 'Submission_Comment'
end

class Mutations::UpdateNotificationPreferences < Mutations::BaseMutation
  graphql_name 'UpdateNotificationPreferences'

  argument :account_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Account')
  argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Course')
  argument :context_type, NotificationPreferencesContextType, required: true

  argument :enabled, Boolean, required: false
  argument :has_read_privacy_notice, Boolean, required: false
  argument :send_scores_in_emails, Boolean, required: false
  argument :send_observed_names_in_notifications, Boolean, required: false

  argument :communication_channel_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('CommunicationChannel')
  argument :notification_category, NotificationCategoryType, required: false
  argument :frequency, NotificationFrequencyType, required: false
  argument :is_policy_override, Boolean, required: false

  field :user, Types::UserType, null: true
  def resolve(input:)
    validate_input(input)
    context = get_context(input)

    if !input[:enabled].nil?
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

    if !input[:send_observed_names_in_notifications].nil?
      current_user.preferences[:send_observed_names_in_notifications] = input[:send_observed_names_in_notifications]
      current_user.save!
    end

    # Because we validate the arguments for updating notification policies above we only need to
    # check for the presence of one of the arguments needed to update notification policies
    if input[:communication_channel_id]
      communication_channel = CommunicationChannel.find(input[:communication_channel_id])
      if input[:is_policy_override]
        NotificationPolicyOverride.create_or_update_for(communication_channel, input[:notification_category].tr('_', ' '), input[:frequency], context)
      else
        NotificationPolicy.find_or_update_for_category(communication_channel, input[:notification_category].tr('_', ' '), input[:frequency])
      end
    end

    {
      user: current_user
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  rescue ActiveRecord::RecordInvalid => invalid
    errors_for(invalid.record)
  rescue => error
    return validation_error(error.message)
  end

  def validate_input(input)
    if input[:context_type] == 'Course'
      raise I18n.t('Course level notification preferences require a course_id to update') unless input[:course_id]
    elsif input[:context_type] == 'Account'
      raise I18n.t('Account level notification preferences require an account_id to update') unless input[:account_id]
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
    if !policy_update_input.all? && !policy_update_input.none?
      raise I18n.t('Notification policies requires the communication channel id, the notification category, and the frequency to update')
    end
  end

  def get_context(input)
    if input[:context_type] == 'Course'
      Course.find(input[:course_id]) if input[:course_id]
    elsif input[:context_type] == 'Account'
      Account.find(input[:account_id]) if input[:account_id]
    end
  end
end
