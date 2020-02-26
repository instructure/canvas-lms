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

class Mutations::UpdateNotificationPreferences < Mutations::BaseMutation
  graphql_name 'UpdateNotificationPreferences'

  argument :account_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Account')
  argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Course')
  argument :context_type, NotificationPreferencesContextType, required: true
  argument :enabled, Boolean, required: true

  field :account, Types::AccountType, null: true
  field :course, Types::CourseType, null: true
  def resolve(input:)
    validate_input(input)
    context = get_context(input)
    NotificationPolicyOverride.enable_for_context(current_user, context, enable: input[:enabled])
    {
      account: input[:context_type] == 'Account' ? context : nil,
      course: input[:context_type] == 'Course' ? context : nil
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
      Course.find(input[:course_id])
    elsif input[:context_type] == 'Account'
      Account.find(input[:account_id])
    end
  end
end
