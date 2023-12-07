# frozen_string_literal: true

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
  class MessageableUserType < ApplicationObjectType
    graphql_name "MessageableUser"

    implements GraphQL::Types::Relay::Node
    global_id_field :id # this is a relay-style "global" identifier
    field :_id, ID, "legacy canvas id", method: :id, null: false

    field :name, String, null: false

    field :short_name, String, null: false

    field :common_courses_connection, Types::EnrollmentType.connection_type, null: true
    def common_courses_connection
      Promise.all([
                    load_association(:enrollments).then do |enrollments|
                      enrollments.each do |enrollment|
                        Loaders::AssociationLoader.for(Enrollment, :course).load(enrollment)
                      end
                    end
                  ]).then { object.enrollments.where(course_id: object.common_courses.keys) }
    end

    field :observer_enrollments_connection, Types::EnrollmentType.connection_type, null: true do
      argument :context_code, String, required: true
    end
    def observer_enrollments_connection(context_code: nil)
      course_context = Context.find_by_asset_string(context_code)
      return nil unless course_context.is_a?(Course)
      return nil unless course_context.user_is_instructor?(current_user)

      course_context.observer_enrollments.where(user: object).active_or_pending.where.not(associated_user_id: nil).distinct
    end

    field :common_groups_connection, Types::GroupType.connection_type, null: true
    def common_groups_connection
      load_association(:groups).then { object.groups.where(id: object.common_groups.keys) }
    end
  end
end
