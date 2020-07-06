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
  argument :context_type, NotificationPreferencesContextType, required: false
  argument :enabled, Boolean, required: false
  argument :communication_channel_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('CommunicationChannel')
  argument :notification_category, NotificationCategoryType, required: false
  argument :frequency, NotificationFrequencyType, required: false

  field :user, Types::UserType, null: true
  def resolve(input:)
    validate_input(input)
    context = get_context(input)

    if context && !input[:enabled].nil?
      NotificationPolicyOverride.enable_for_context(current_user, context, enable: input[:enabled])
    end

    if input[:communication_channel_id] && input[:notification_category] && input[:frequency]
      communication_channel = CommunicationChannel.find(input[:communication_channel_id])
      if context
        NotificationPolicyOverride.create_or_update_for(communication_channel, input[:notification_category].gsub('_', ' '), input[:frequency], context)
      else
        NotificationPolicy.find_or_update_for_category(communication_channel, input[:notification_category].gsub('_', ' '), input[:frequency])
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
  end

  def get_context(input)
    if input[:context_type] == 'Course'
      Course.find(input[:course_id]) if input[:course_id]
    elsif input[:context_type] == 'Account'
      Account.find(input[:account_id]) if input[:account_id]
    end
  end
end
