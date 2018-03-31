#
# Copyright (C) 2018 - present Instructure, Inc.
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
  UserType = GraphQL::ObjectType.define do
    #
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #   NOTE:
    #   when adding fields to this type, make sure you are checking the
    #   personal info exclusions as is done in +user_json+
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #
    name "User"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :name, types.String
    field :sortableName, types.String,
      "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
      property: :sortable_name
    field :shortName, types.String,
      "A short name the user has selected, for use in conversations or other less formal places through the site.",
      property: :short_name

    field :avatarUrl, UrlType do
      resolve ->(user, _, ctx) {
        user.account.service_enabled?(:avatars) ?
          AvatarHelper.avatar_url_for_user(user, ctx[:request]) :
          nil
      }
    end

    field :email, types.String, resolve: ->(user, _, ctx) {
      return nil unless user.grants_right? ctx[:current_user], :read_profile

      if user.email_cached?
        user.email
      else
        Loaders::AssociationLoader.for(User, :communication_channels).
          load(user).
          then { user.email }
      end
    }

    field :enrollments, !types[EnrollmentType] do
      argument :courseId, types.ID,
        "only return enrollments for this course",
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")

      resolve ->(user, args, ctx) do
        course_ids = [args[:courseId]].compact
        Loaders::UserCourseEnrollmentLoader.for(
          course_ids: course_ids
        ).load(user.id).then do |enrollments|
          (enrollments || []).select { |enrollment|
            user == ctx[:current_user] ||
              enrollment.grants_right?(ctx[:current_user], ctx[:session], :read)
          }
        end
      end
    end

    field :summaryAnalytics, StudentSummaryAnalyticsType do
      argument :courseId, !types.ID,
        "returns summary analytics for this course",
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")

      resolve ->(user, args, ctx) do
        Loaders::CourseStudentAnalyticsLoader.for(
          args[:courseId],
          current_user: ctx[:current_user], session: ctx[:session]
        ).load(user)
      end
    end
  end
end

module Loaders
  class UserCourseEnrollmentLoader < Loaders::ForeignKeyLoader
    def initialize(course_ids:)
      scope = Enrollment.joins(:course).
        where.not(enrollments: {workflow_state: "deleted"},
                  courses: {workflow_state: "deleted"})

      scope = scope.where(course_id: course_ids) if course_ids.present?

      super(scope, :user_id)
    end
  end
end
