#
# Copyright (C) 2019 - present Instructure, Inc.
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
  class AccountType < ApplicationObjectType
    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :name, String, null: true

    field :proficiency_ratings_connection, ProficiencyRatingType.connection_type, null: true
    def proficiency_ratings_connection
      # This does a recursive lookup of parent accounts, not sure how we could
      # batch load it in a reasonable way.
      object.resolved_outcome_proficiency&.outcome_proficiency_ratings
    end

    field :courses_connection, CourseType.connection_type, null: true
    def courses_connection
      return unless object.grants_right?(current_user, :read_course_list)
      object.associated_courses
    end

    field :sub_accounts_connection, AccountType.connection_type, null: true
    def sub_accounts_connection
      object.sub_accounts.order(:id)
    end

    field :notification_preferences_enabled, Boolean, null: false
    def notification_preferences_enabled
      NotificationPolicyOverride.enabled_for(current_user, object)
    end
  end
end
