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

    field :pronouns, String, null: true

    field :sis_id, String, null: true
    def sis_id
      # Check if feature flag is enabled
      # TODO: clean :inbox_sis_id_for_duplicates flag after release, VICE-5840
      return unless Account.site_admin.feature_enabled?(:inbox_sis_id_for_duplicates)

      # Check account/course permissions before user-level to avoid N+1 queries.
      # In course context, skip expensive object.grants_any_right? that loads all user enrollments.
      domain_root_account = context[:domain_root_account]
      unless domain_root_account.grants_any_right?(context[:current_user], :read_sis, :manage_sis)
        course = context[:course]
        has_permission = if course
                           course.grants_any_right?(context[:current_user], :read_sis, :manage_sis)
                         else
                           object.grants_any_right?(context[:current_user], :read_sis, :manage_sis)
                         end

        return unless has_permission
      end

      load_association(:pseudonyms).then do
        pseudonym = SisPseudonym.for(object,
                                     domain_root_account,
                                     type: :implicit,
                                     require_sis: false,
                                     root_account: domain_root_account,
                                     in_region: true,
                                     current_user: context[:current_user])
        pseudonym&.sis_user_id
      end
    end

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
