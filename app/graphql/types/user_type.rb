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
  class DashboardObserveeFilterInputType < BaseInputObject
    graphql_name "DashboardObserveeFilter"
    argument :observed_user_id,
             ID,
             "Only view filtered user",
             required: false
  end

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

    field :first_name, HtmlEncodedStringType, null: true
    field :last_name, HtmlEncodedStringType, null: true
    field :name, HtmlEncodedStringType, null: true
    field :short_name,
          HtmlEncodedStringType,
          "A short name the user has selected, for use in conversations or other less formal places through the site.",
          null: true
    field :sortable_name,
          HtmlEncodedStringType,
          "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
          null: true

    field :pronouns, String, null: true

    field :discussions_splitscreen_view, Boolean, null: false
    def discussions_splitscreen_view
      object.discussions_splitscreen_view?
    end

    field :avatar_url, UrlType, null: true

    def avatar_url
      Loaders::AssociationLoader.for(User, :pseudonym).load(object).then do
        if object.account.service_enabled?(:avatars)
          AvatarHelper.avatar_url_for_user(object, context[:request], use_fallback: false)
        else
          nil
        end
      end
    end

    field :html_url, UrlType, null: true do
      argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
    end
    def html_url(course_id: nil)
      resolved_course_id = course_id.nil? ? context[:course_id] : course_id

      if context[:group_id]
        GraphQLHelpers::UrlHelpers.group_user_url(
          group_id: context[:group_id],
          id: object.id,
          host: context[:request].host_with_port
        )
      elsif resolved_course_id
        # it is possible to be a user in an admin group discussion where is no course
        GraphQLHelpers::UrlHelpers.course_user_url(
          course_id: resolved_course_id,
          id: object.id,
          host: context[:request].host_with_port
        )
      end
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
         context[:course]&.grants_any_right?(context[:current_user], :read_sis, :manage_sis) ||
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
         context[:course]&.grants_any_right?(context[:current_user], :read_sis, :manage_sis) ||
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

    ALLOWED_ORDER_BY_VALUES = %w[id user_id course_id created_at start_at end_at completed_at courses.id courses.name courses.course_code courses.start_at courses.conclude_at].to_set

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
      argument :exclude_concluded,
               Boolean,
               "Whether or not to exclude `completed` enrollments",
               required: false
      argument :horizon_courses,
               Boolean,
               "Whether or not to include or exclude Canvas Career courses",
               required: false
      argument :order_by,
               [String],
               "The fields to order the results by",
               required: false,
               validates: { all: { inclusion: { in: ALLOWED_ORDER_BY_VALUES } } }
      argument :sort,
               EnrollmentsSortInputType,
               "The sort field and direction for the results. Secondary sort is by section name",
               required: false
    end

    # TODO: handle N+1
    field :login_id, String, null: true
    def login_id
      course = context[:course]
      return nil unless course
      return nil unless course.grants_right?(current_user, session, :view_user_logins)

      pseudonym = SisPseudonym.for(
        object,
        course,
        type: :implicit,
        require_sis: false,
        root_account: context[:domain_root_account],
        in_region: true
      )
      return nil unless pseudonym

      pseudonym.unique_id
    end

    def enrollments(course_id: nil, current_only: false, order_by: [], exclude_concluded: false, horizon_courses: nil, sort: {})
      course_ids = [course_id].compact
      Loaders::UserCourseEnrollmentLoader.for(
        course_ids:,
        order_by:,
        current_only:,
        exclude_concluded:,
        horizon_courses:,
        sort:
      ).load(object.id).then do |enrollments|
        (enrollments || []).select do |enrollment|
          object == context[:current_user] ||
            enrollment.grants_right?(context[:current_user], context[:session], :read)
        end
      end
    end

    field :notification_preferences_enabled, Boolean, null: false do
      argument :account_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Account")
      argument :context_type, NotificationPreferencesContextType, required: true
      argument :course_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
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
      argument :filter, [String], required: false
      argument :scope, String, required: false
      argument :show_horizon_conversations, Boolean, required: false
    end
    def conversations_connection(scope: nil, filter: nil, show_horizon_conversations: false)
      if object == context[:current_user]

        conversations_scope = case scope
                              when "unread"
                                InstStatsd::Statsd.distributed_increment("inbox.visit.scope.unread.pages_loaded.react")
                                object.conversations.unread
                              when "starred"
                                InstStatsd::Statsd.distributed_increment("inbox.visit.scope.starred.pages_loaded.react")
                                object.starred_conversations
                              when "sent"
                                InstStatsd::Statsd.distributed_increment("inbox.visit.scope.sent.pages_loaded.react")
                                object.all_conversations.sent
                              when "archived"
                                InstStatsd::Statsd.distributed_increment("inbox.visit.scope.archived.pages_loaded.react")
                                object.conversations.archived
                              else
                                InstStatsd::Statsd.distributed_increment("inbox.visit.scope.inbox.pages_loaded.react")
                                object.conversations.default
                              end

        # Filter out conversations from horizon courses unless explicitly shown
        unless show_horizon_conversations
          # Get IDs of horizon courses where the user is a student
          horizon_student_course_ids = object.enrollments
                                             .where(type: "StudentEnrollment")
                                             .joins(:course)
                                             .where(courses: { workflow_state: "available" })
                                             .horizon
                                             .pluck(:course_id)
          # Get IDs of conversations that have messages from horizon courses
          horizon_conversation_ids = conversations_scope
                                     .where(
                                       tags: horizon_student_course_ids.map { |c| "course_#{c}" }
                                     )
                                     .pluck(:id)
          conversations_scope = conversations_scope.where.not(id: horizon_conversation_ids) if horizon_student_course_ids.present? && horizon_conversation_ids.present?
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
      argument :context, String, required: false
      argument :search, String, required: false
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
          base_url: self.context[:request].base_url,
          include_concluded: false
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
      argument :context_code, String, required: true
      argument :recipient_ids, [String], required: true
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

    field :group_memberships, [GroupMembershipType], null: false do
      argument :filter, Types::UserGroupMembershipsFilterInputType, required: false
    end
    def group_memberships(filter: {})
      Loaders::UserLoaders::GroupMembershipsLoader.for(filter:).load(object.id)
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

    field :favorite_courses_connection, Types::CourseType.connection_type, null: true do
      argument :dashboard_filter, Types::DashboardObserveeFilterInputType, required: false
    end
    def favorite_courses_connection(dashboard_filter: nil)
      return unless object == current_user

      load_association(:enrollments).then do |enrollments|
        Promise.all([
                      Loaders::AssociationLoader.for(Enrollment, :course).load_many(enrollments),
                      load_association(:favorites)
                    ]).then do
          opts = {}
          if dashboard_filter&.dig(:observed_user_id).present?
            observed_user_id = dashboard_filter[:observed_user_id].to_i
            opts[:observee_user] = User.find_by(id: observed_user_id) || current_user
          end

          menu_courses = object.menu_courses(nil, opts)
          published, unpublished = menu_courses.partition(&:published?)

          Rails.cache.write(["last_known_dashboard_cards_published_count", current_user.global_id].cache_key, published.count)
          Rails.cache.write(["last_known_dashboard_cards_unpublished_count", current_user.global_id].cache_key, unpublished.count)
          Rails.cache.write(["last_known_k5_cards_count", current_user.global_id].cache_key, menu_courses.count { |course| !course.homeroom_course? })

          menu_courses
        end
      end
    end

    def get_favorite_groups(scope)
      favorite_group_ids = object.favorite_context_ids("Group")
      favorite_groups = scope.where(id: favorite_group_ids)

      # Return favorite groups if any exist; otherwise, return the provided scope
      favorite_groups.exists? ? favorite_groups : scope
    end

    field :favorite_groups_connection, Types::GroupType.connection_type, null: true do
      description "Favorite groups for the user."
      argument :include_non_collaborative, Boolean, required: false, default_value: false
    end
    def favorite_groups_connection(include_non_collaborative: false)
      # Ensure that the field is accessed by the current user
      return unless object == current_user

      load_association(:groups).then do |groups|
        collaborative_scope = groups.active.shard(object)
        final_scope = collaborative_scope

        if include_non_collaborative
          load_association(:differentiation_tags).then do |differentiation_tags|
            non_collaborative_scope = differentiation_tags.active.shard(object)

            # non_collaborative groups where the current user does not have read access
            non_viewable_group_ids = non_collaborative_scope
                                     .reject { |group| group.grants_right?(object, :read) }
                                     .map(&:id)
            non_collaborative_scope = non_collaborative_scope.where.not(id: non_viewable_group_ids)
            final_scope = collaborative_scope.or(non_collaborative_scope)

            get_favorite_groups(final_scope)
          end
        else
          get_favorite_groups(final_scope)
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
      InstStatsd::Statsd.distributed_increment("inbox.visit.scope.submission_comments.pages_loaded.react")
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
      argument :built_in_only, Boolean, "Only return default/built_in roles", required: false
      argument :course_id, String, required: false
      argument :role_types, [String], "Return only requested base role types", required: false
    end
    def course_roles(course_id: nil, role_types: nil, built_in_only: true)
      # This graphql execution context can be used to set course_id if you are calling course_role from a nested query
      resolved_course_id = course_id.nil? ? context[:course_id] : course_id
      return if resolved_course_id.nil?

      Loaders::CourseRoleLoader.for(course_id: resolved_course_id, role_types:, built_in_only:).load(object)
    end

    field :course_progression, CourseProgressionType, <<~MD, null: true # rubocop:disable GraphQL/ExtractType
      Returns null if either of these conditions are met:
      * the course is not module based
      * no module in it has completion requirements
      * the queried user is not a student in the course
      * insufficient permissions for the request
    MD
    def course_progression
      target_user = object
      course = context[:course]
      return if course.nil?
      return unless course.grants_right?(current_user, session, :view_all_grades) || target_user.grants_right?(current_user, session, :read)

      progress = CourseProgress.new(context[:course], object, read_only: true)
      return unless progress.can_evaluate_progression?

      progress
    end

    field :inbox_labels, [String], null: true
    def inbox_labels
      return unless object == current_user

      object.inbox_labels
    end

    field :activity_stream, ActivityStreamType, null: true do
      argument :only_active_courses, Boolean, required: false
    end
    def activity_stream(only_active_courses: false)
      return unless object == current_user

      context.scoped_set!(:only_active_courses, only_active_courses)
      context.scoped_set!(:context_type, "User")
      object
    end
  end
end

module Loaders
  class UserCourseEnrollmentLoader < Loaders::ForeignKeyLoader
    def initialize(course_ids:, order_by: [], current_only: false, exclude_concluded: false, exclude_pending_enrollments: true, horizon_courses: nil, sort: {})
      scope = if horizon_courses
                Enrollment.horizon
              elsif horizon_courses == false
                Enrollment.not_horizon
              else
                Enrollment.joins(:course)
              end

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

      if sort.present?
        sort_direction = (sort[:direction] == "desc") ? "DESC" : "ASC"
        reversed_sort_direction = (sort[:direction] == "desc") ? "ASC" : "DESC"

        case sort[:field]
        when "last_activity_at"
          # The order for last_activity_at is intentionally reversed because last activity is
          # a timestamp and we want the most recent activity to appear first in ascending order
          scope = scope.joins(:course_section)
                       .select("enrollments.*, course_sections.name as section_name")
                       .order("last_activity_at #{reversed_sort_direction} NULLS LAST, section_name ASC")
        when "section_name"
          scope = scope.joins(:course_section)
                       .select("enrollments.*, course_sections.name as section_name")
                       .order("section_name #{sort_direction} NULLS LAST")
        when "role"
          # use the same role ordering as the one in lib/user_search.rb
          scope = scope.joins(:course_section)
                       .select("enrollments.*, course_sections.name as section_name,
                                (CASE
                                  WHEN type = 'TeacherEnrollment' THEN 0
                                  WHEN type = 'TaEnrollment' THEN 1
                                  WHEN type = 'StudentEnrollment' THEN 2
                                  WHEN type = 'ObserverEnrollment' THEN 3
                                  WHEN type = 'DesignerEnrollment' THEN 4
                                  ELSE NULL
                                END) as role")
                       .order("role #{sort_direction} NULLS LAST, section_name ASC")
        end
      end

      super(scope, :user_id)
    end
  end
end
