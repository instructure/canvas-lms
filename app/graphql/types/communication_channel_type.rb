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

module Types
  class CommunicationChannelType < ApplicationObjectType
    graphql_name "CommunicationChannel"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :path, String, null: true

    field :path_type, String, null: true

    field :notification_policies, [NotificationPolicyType], null: true
    def notification_policies
      NotificationPolicy.find_all_for(self.object)
    end

    field :notification_policy_overrides, [NotificationPolicyType], null: true do
      argument :account_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Account')
      argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Course')
      argument :context_type, NotificationPreferencesContextType, required: true
    end
    def notification_policy_overrides(account_id: nil, course_id: nil, context_type: nil)
      overrides_for = ->(context) do
        NotificationPolicyOverride.find_all_for(current_user, context, object.id)
      end

      case context_type
      when 'Account'
        overrides_for[Account.find(account_id)]
      when 'Course'
        overrides_for[Course.find(course_id)]
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
