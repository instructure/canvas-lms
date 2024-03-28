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

    include SearchHelper
    include Api::V1::StreamItem
    include ConversationsHelper

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :name, String, null: true
    field :sortable_name,
          String,
          "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
          null: true
    field :short_name,
          String,
          "A short name the user has selected, for use in conversations or other less formal places through the site.",
          null: true

    field :pronouns, String, null: true

    field :discussions_splitscreen_view, Boolean, null: false
    def discussions_splitscreen_view
      object.discussions_splitscreen_view?
    end

    field :avatar_url, UrlType, null: true

    def avatar_url
      if object.account.service_enabled?(:avatars)
        AvatarHelper.avatar_url_for_user(object, context[:request], use_fallback: false)
      else
        nil
      end
    end

    field :html_url, UrlType, null: true do
      argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
    end
    def html_url(course_id: nil)
      resolved_course_id = course_id.nil? ? context[:course_id] : course_id
      return if resolved_course_id.nil?

      GraphQLHelpers::UrlHelpers.course_user_url(
        course_id: resolved_course_id,
        id: object.id,
        host: context[:request].host_with_port
      )
    end

    field :email, String, null: true

    def email
      return nil unless object.grants_all_rights?(context[:current_user], :read_profile, :read_email_addresses)

      return object.email if object.email_cached?

      Loaders::AssociationLoader.for(User, :communication_channels)
                                .load(object)
                                .then { object.email }
    end

    field :uuid, String, null: true

    field :sis_id, String, null: true
    def sis_id
      domain_root_account = context[:domain_root_account]
      if domain_root_account.grants_any_right?(context[:current_user], :read_sis, :manage_sis) ||
         object.grants_any_right?(context[:current_user], :read_sis, :manage_sis)
        Loaders::AssociationLoader.for(User, :pseudonyms)
                                  .load(object)
                                  .then do
          pseudonym = SisPseudonym.for(object,
                                       domain_root_account,
                                       type: :implicit,
                                       require_sis: false,
                                       root_account: domain_root_account,
                                       in_region: true)
          pseudonym&.sis_user_id
        end
      end
    end

    field :integration_id, String, null: true
    def integration_id
      domain_root_account = context[:domain_root_account]
      if domain_root_account.grants_any_right?(context[:current_user], :read_sis, :manage_sis) ||
         object.grants_any_right?(context[:current_user], :read_sis, :manage_sis)
        Loaders::AssociationLoader.for(User, :pseudonyms)
                                  .load(object)
                                  .then do
          pseudonym = SisPseudonym.for(object,
                                       domain_root_account,
                                       type: :implicit,
                                       require_sis: false,
                                       root_account: domain_root_account,
                                       in_region: true)
          pseudonym&.integration_id
        end
      end
    end

    field :enrollments, [EnrollmentType], null: false do
      argument :course_id,
               ID,
               "only return enrollments for this course",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
      argument :current_only,
               Boolean,
               "Whether or not to restrict results to `active` enrollments in `available` courses",
               required: false
      argument :order_by,
               [String],
               "The fields to order the results by",
               required: false
      argument :exclude_concluded,
               Boolean,
               "Whether or not to exclude `completed` enrollments",
               required: false
    end

    field :login_id, String, null: true
    def login_id
      course = context[:course]
      return nil unless course

      pseudonym = SisPseudonym.for(
        object,
        course,
        type: :implicit,
        require_sis: false,
        root_account: context[:domain_root_account],
        in_region: true
      )
      return nil unless pseudonym && course.grants_right?(context[:current_user], context[:session], :view_user_logins)

      pseudonym.unique_id
    end

    def enrollments(course_id: nil, current_only: false, order_by: [], exclude_concluded: false)
      course_ids = [course_id].compact
      Loaders::UserCourseEnrollmentLoader.for(
        course_ids:,
        order_by:,
        current_only:,
        exclude_concluded:
      ).load(object.id).then do |enrollments|
        (enrollments || []).select do |enrollment|
          object == context[:current_user] ||
            enrollment.grants_right?(context[:current_user], context[:session], :read)
        end
      end
    end

    field :notification_preferences_enabled, Boolean, null: false do
      argument :account_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Account")
      argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
      argument :context_type, NotificationPreferencesContextType, required: true
    end
    def notification_preferences_enabled(account_id: nil, course_id: nil, context_type: nil)
      enabled_for = lambda do |context|
        NotificationPolicyOverride.enabled_for(object, context)
      end

      case context_type
      when "Account"
        enabled_for[Account.find(account_id)]
      when "Course"
        enabled_for[Course.find(course_id)]
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    field :notification_preferences, NotificationPreferencesType, null: true
    def notification_preferences
      return nil unless object.grants_all_rights?(context[:current_user], :read_profile, :read_email_addresses)

      Loaders::AssociationLoader.for(User, :communication_channels).load(object).then do |comm_channels|
        {
          channels: comm_channels.supported.unretired,
          user: object
        }
      end
    end

    field :conversations_connection, Types::ConversationParticipantType.connection_type, null: true do
      argument :scope, String, required: false
      argument :filter, [String], required: false
    end
    def conversations_connection(scope: nil, filter: nil)
      if object == context[:current_user]
        conversations_scope = case scope
                              when "unread"
                                InstStatsd::Statsd.increment("inbox.visit.scope.unread.pages_loaded.react")
                                object.conversations.unread
                              when "starred"
                                InstStatsd::Statsd.increment("inbox.visit.scope.starred.pages_loaded.react")
                                object.starred_conversations
                              when "sent"
                                InstStatsd::Statsd.increment("inbox.visit.scope.sent.pages_loaded.react")
                                object.all_conversations.sent
                              when "archived"
                                InstStatsd::Statsd.increment("inbox.visit.scope.archived.pages_loaded.react")
                                object.conversations.archived
                              else
                                InstStatsd::Statsd.increment("inbox.visit.scope.inbox.pages_loaded.react")
                                object.conversations.default
                              end

        filter_mode = :and
        filter = filter.presence || []
        filters = filter.select(&:presence)
        conversations_scope = conversations_scope.tagged(*filters, mode: filter_mode) if filters.present?
        conversations_scope
      end
    end

    field :total_recipients, Integer, null: false do
      argument :context, String, required: false
    end
    def total_recipients(context: nil)
      return nil unless object == self.context[:current_user]

      @current_user = object

      normalize_recipients(recipients: context, context_code: context)&.count || 0
    end

    field :recipients, RecipientsType, null: true do
      argument :search, String, required: false
      argument :context, String, required: false
    end
    def recipients(search: nil, context: nil)
      return nil unless object == self.context[:current_user]

      GuardRail.activate(:secondary) do
        @current_user = object
        search_context = AddressBook.load_context(context)

        load_all_contexts(
          context: search_context,
          permissions: [:send_messages, :send_messages_all],
          base_url: self.context[:request].base_url
        )

        collections = search_contexts_and_users(
          search:,
          context:,
          synthetic_contexts: true,
          messageable_only: true,
          base_url: self.context[:request].base_url
        )

        contexts_collection = collections.select { |c| c[0] == "contexts" }
        users_collection = collections.select { |c| c[0] == "participants" }

        contexts_collection = contexts_collection[0][1] if contexts_collection.count > 0
        users_collection = users_collection[0][1] if users_collection.count > 0

        can_send_all = if search_context.nil?
                         false
                       elsif search_context.is_a?(Course)
                         search_context.grants_any_right?(object, :send_messages_all)
                       elsif !search_context.course.nil?
                         search_context.course.grants_any_right?(object, :send_messages_all)
                       end

        # The contexts_connection and users_connection return types of custom Collections
        # These special data structures are handled in the collection_connection.rb files
        {
          sendMessagesAll: !!can_send_all,
          contexts_connection: contexts_collection,
          users_connection: users_collection
        }
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    field :recipients_observers, MessageableUserType.connection_type, null: true do
      argument :recipient_ids, [String], required: true
      argument :context_code, String, required: true
    end
    def recipients_observers(recipient_ids: nil, context_code: nil)
      return nil unless object == context[:current_user]

      # This field will only be used for conversations with a course context
      course_context = Context.find_by_asset_string(context_code)
      return nil unless course_context.is_a?(Course)

      # Setting this global variable is required for helper functions to run correctly
      @current_user = object
      normalized_recipient_ids = normalize_recipients(recipients: recipient_ids, context_code:).map(&:id)
      course_observers_observing_recipients_ids = course_context.enrollments.not_fake.active_by_date.of_observer_type.where(associated_user_id: normalized_recipient_ids).distinct.pluck(:user_id)

      # Normalize recipients should remove any observers that the current user is not able to message
      normalize_recipients(recipients: course_observers_observing_recipients_ids, context_code:)
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
    field :groups, [GroupType], <<~MD, null: true
      **NOTE**: this only returns groups for the currently logged-in user.
    MD
    def groups
      if object == current_user
        # FIXME: this only returns groups on the current shard.  it should
        # behave like the REST API (see GroupsController#index)
        current_user.visible_groups
      end
    end

    field :summary_analytics, StudentSummaryAnalyticsType, null: true do
      argument :course_id,
               ID,
               "returns summary analytics for this course",
               required: true,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
    end

    def summary_analytics(course_id:)
      Loaders::CourseStudentAnalyticsLoader.for(
        course_id,
        current_user: context[:current_user],
        session: context[:session]
      ).load(object)
    end

    field :favorite_courses_connection, Types::CourseType.connection_type, null: true
    def favorite_courses_connection
      return unless object == current_user

      load_association(:enrollments).then do |enrollments|
        Promise.all([
                      Loaders::AssociationLoader.for(Enrollment, :course).load_many(enrollments),
                      load_association(:favorites)
                    ]).then do
          object.menu_courses
        end
      end
    end

    field :favorite_groups_connection, Types::GroupType.connection_type, null: true
    def favorite_groups_connection
      return unless object == current_user

      load_association(:groups).then do |groups|
        load_association(:favorites).then do
          favorite_groups = groups.active.shard(object).where(id: object.favorite_context_ids("Group"))
          favorite_groups.any? ? favorite_groups : object.groups.active.shard(object)
        end
      end
    end

    field :viewable_submissions_connection, Types::SubmissionType.connection_type, null: true do
      description "All submissions with comments that the current_user is able to view"
      argument :filter, [String], required: false
    end
    def viewable_submissions_connection(filter: nil)
      return unless object == current_user

      @current_user = current_user
      submissions = []

      opts = {
        only_active_courses: true,
        asset_type: "Submission"
      }

      filter&.each do |f|
        matches = f.match(/.*(course|user)_(\d+)/)
        if matches.present?
          case matches[1]
          when "course"
            opts[:context] = Context.find_by_asset_string(matches[0])
          when "user"
            opts[:submission_user_id] = matches[2].to_i
          end
        end
        next
      end

      ssi_scope = current_user.visible_stream_item_instances(opts).preload(:stream_item)
      is_cross_shard = current_user.visible_stream_item_instances(opts).where("stream_item_id > ?", Shard::IDS_PER_SHARD).exists?
      if is_cross_shard
        # the old join doesn't work for cross-shard stream items, so we basically have to pre-calculate everything
        ssi_scope = ssi_scope.where(stream_item_id: filtered_stream_item_ids(opts))
      else
        ssi_scope = ssi_scope.eager_load(:stream_item).where("stream_items.asset_type=?", "Submission")
        ssi_scope = ssi_scope.joins("INNER JOIN #{Submission.quoted_table_name} ON submissions.id=asset_id")
        ssi_scope = ssi_scope.where("submissions.workflow_state <> 'deleted' AND submissions.submission_comments_count>0")
        ssi_scope = ssi_scope.where("submissions.user_id=?", opts[:submission_user_id]) if opts.key?(:submission_user_id)
      end

      Shard.partition_by_shard(ssi_scope, ->(sii) { sii.stream_item_id }) do |shard_stream_items|
        submission_ids = StreamItem.where(id: shard_stream_items.map(&:stream_item_id)).pluck(:asset_id)
        submissions += Submission.where(id: submission_ids)
      end
      InstStatsd::Statsd.increment("inbox.visit.scope.submission_comments.pages_loaded.react")
      # on FE we use newest submission comment to render date so use that first.
      submissions.sort_by { |t| t.submission_comments.last.created_at || t.last_comment_at }.reverse
    rescue
      []
    end

    field :comment_bank_items_connection, Types::CommentBankItemType.connection_type, null: true do
      argument :query, String, <<~MD, required: false
        Only include comments that match the query string.
      MD
      argument :limit, Integer, required: false
    end
    def comment_bank_items_connection(query: nil, limit: nil)
      return unless object == current_user

      comments = current_user.comment_bank_items.shard(object)

      comments = comments.where(ActiveRecord::Base.wildcard("comment", query.strip)) if query&.strip.present?
      # .to_a gets around the .shard() bug documented in FOO-1989 so that it can be properly limited.
      # After that bug is fixed and Switchman is upgraded in Canvas, we can remove the block below
      # and use the 'first' argument on the connection instead of 'limit'.
      # Note that limit: 5 is currently being used by the Comment Library.
      if limit.present?
        comments = comments.limit(limit).to_a.first(limit)
      end

      comments
    end

    field :course_roles, [String], null: true do
      argument :course_id, String, required: false
      argument :role_types, [String], "Return only requested base role types", required: false
      argument :built_in_only, Boolean, "Only return default/built_in roles", required: false
    end
    def course_roles(course_id: nil, role_types: nil, built_in_only: true)
      # This graphql execution context can be used to set course_id if you are calling course_role from a nested query
      resolved_course_id = course_id.nil? ? context[:course_id] : course_id
      return if resolved_course_id.nil?

      Loaders::CourseRoleLoader.for(course_id: resolved_course_id, role_types:, built_in_only:).load(object)
    end

    field :inbox_labels, [String], null: true
    def inbox_labels
      return unless object == current_user

      object.inbox_labels
    end
  end
end

module Loaders
  class UserCourseEnrollmentLoader < Loaders::ForeignKeyLoader
    def initialize(course_ids:, order_by: [], current_only: false, exclude_concluded: false, exclude_pending_enrollments: true)
      scope = Enrollment.joins(:course)

      scope = if current_only
                scope.current.active_by_date
              else
                scope.where.not(enrollments: { workflow_state: "deleted" })
                     .where.not(courses: { workflow_state: "deleted" })
              end

      scope = scope.where(course_id: course_ids) if course_ids.present?

      scope = scope.where.not(enrollments: { workflow_state: "completed" }) if exclude_concluded

      scope = scope.excluding_pending if exclude_pending_enrollments

      order_by.each { |o| scope = scope.order(o) }

      super(scope, :user_id)
    end
  end
end
