# frozen_string_literal: true

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

class NotificationPreferencesContextType < Types::BaseEnum
  graphql_name 'NotificationPreferencesContextType'
  description 'Context types that can be associated with notification preferences'
  value 'Course'
  value 'Account'
end

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
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :name, String, null: true
    field :sortable_name, String,
      "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
      null: true
    field :short_name, String,
      "A short name the user has selected, for use in conversations or other less formal places through the site.",
      null: true

    field :pronouns, String, null: true

    field :avatar_url, UrlType, null: true

    def avatar_url
      object.account.service_enabled?(:avatars) ?
        AvatarHelper.avatar_url_for_user(object, context[:request], use_fallback: false) :
        nil
    end

    field :email, String, null: true

    def email
      return nil unless object.grants_all_rights?(context[:current_user], :read_profile, :read_email_addresses)

      return object.email if object.email_cached?

      Loaders::AssociationLoader.for(User, :communication_channels).
        load(object).
        then { object.email }
    end

    field :sis_id, String, null: true
    def sis_id
      domain_root_account = context[:domain_root_account]
      if domain_root_account.grants_any_right?(context[:current_user], :read_sis, :manage_sis) ||
        object.grants_any_right?(context[:current_user], :read_sis, :manage_sis)
        Loaders::AssociationLoader.for(User, :pseudonyms).
          load(object).
          then do
            pseudonym = SisPseudonym.for(object, domain_root_account, type: :implicit, require_sis: false,
                root_account: domain_root_account, in_region: true)
            pseudonym&.sis_user_id
          end
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

    field :trophies, [TrophyType], null: true
    def trophies
      Loaders::AssociationLoader.for(User, :trophies).load(object).then do |trophies|
        locked_trophies = Trophy.trophy_names - trophies.map(&:name)
        trophies.to_a.concat(locked_trophies.map { |name| Trophy.blank_trophy(name) })
      end
    end

    field :notification_preferences_enabled, Boolean, null: false do
      argument :account_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Account')
      argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Course')
      argument :context_type, NotificationPreferencesContextType, required: true
    end
    def notification_preferences_enabled(account_id: nil, course_id: nil, context_type: nil)
      enabled_for = ->(context) do
        NotificationPolicyOverride.enabled_for(object, context)
      end

      case context_type
      when 'Account'
        enabled_for[Account.find(account_id)]
      when 'Course'
        enabled_for[Course.find(course_id)]
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    field :notification_preferences, NotificationPreferencesType, null: true
    def notification_preferences
      Loaders::AssociationLoader.for(User, :communication_channels).load(object).then do |comm_channels|
        {
          channels: comm_channels.unretired,
          user: object
        }
      end
    end

    field :conversations_connection, Types::ConversationParticipantType.connection_type, null: true
    def conversations_connection
      load_association(:all_conversations).then do
        object.conversations
      end
    end

    # TODO: deprecate this
    #
    # we should probably have some kind of top-level field called `self` or
    # `currentUser` or `viewer` that holds this kind of info.
    #
    # (there is no way to view another user's groups via the REST API)
    #
    # alternatively, figure out what kind of permissions a person needs to view
    # another user's groups?
    field :groups, [GroupType], <<~DESC, null: true
      **NOTE**: this only returns groups for the currently logged-in user.
    DESC
    def groups
      if object == current_user
        # FIXME: this only returns groups on the current shard.  it should
        # behave like the REST API (see GroupsController#index)
        load_association(:current_groups)
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
