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
  class UserType < ApplicationObjectType
    #
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #   NOTE:
    #   when adding fields to this type, make sure you are checking the
    #   personal info exclusions as is done in +user_json+
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #
    graphql_name "User"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface

    global_id_field :id
    field :_id, ID, "legacy canvas id", null: false, method: :id

    field :name, String, null: true
    field :sortable_name, String,
      "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
      null: true
    field :short_name, String,
      "A short name the user has selected, for use in conversations or other less formal places through the site.",
      null: true

    field :avatar_url, UrlType, null: true

    def avatar_url
      object.account.service_enabled?(:avatars) ?
        AvatarHelper.avatar_url_for_user(object, context[:request], use_fallback: false) :
        nil
    end

    field :email, String, null: true

    def email
      return nil unless object.grants_right? context[:current_user], :read_profile
      if object.email_cached?
        object.email
      else
        Loaders::AssociationLoader.for(User, :communication_channels).
          load(object).
          then { object.email }
      end
    end

    field :enrollments, [EnrollmentType], null: false do
      argument :course_id, ID,
        "only return enrollments for this course",
        required: false,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
    end

    def enrollments(course_id: nil)
      course_ids = [course_id].compact
      Loaders::UserCourseEnrollmentLoader.for(
        course_ids: course_ids
      ).load(object.id).then do |enrollments|
        (enrollments || []).select { |enrollment|
          object == context[:current_user] ||
            enrollment.grants_right?(context[:current_user], context[:session], :read)
        }
      end
    end

    field :summary_analytics, StudentSummaryAnalyticsType, null: true do
      argument :course_id, ID,
        "returns summary analytics for this course",
        required: true,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
    end

    def summary_analytics(course_id:)
      Loaders::CourseStudentAnalyticsLoader.for(
        course_id,
        current_user: context[:current_user], session: context[:session]
      ).load(object)
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
