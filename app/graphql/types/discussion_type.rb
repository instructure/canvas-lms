# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
  class DiscussionFilterType < Types::BaseEnum
    graphql_name "DiscussionFilterType"
    description "Search types that can be associated with discussions"
    value "all"
    value "unread"
    value "drafts"
    value "deleted"
  end

  class Types::DiscussionTopicAnonymousStateType < Types::BaseEnum
    graphql_name "DiscussionTopicAnonymousStateType"
    description "Anonymous states for discussionTopics"
    value "partial_anonymity"
    value "full_anonymity"
    value "off"
  end

  class Types::DiscussionTopicDiscussionType < Types::BaseEnum
    graphql_name "DiscussionTopicDiscussionType"
    description "Discussion type for discussionTopics"
    value "not_threaded"
    value "threaded"
    value "flat"
    value "side_comment"
  end

  class DiscussionType < ApplicationObjectType
    graphql_name "Discussion"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface
    implements Interfaces::LegacyIDInterface

    include Rails.application.routes.url_helpers
    include Canvas::LockExplanation

    global_id_field :id
    field :allow_rating, Boolean, null: true
    field :anonymous_state, DiscussionTopicAnonymousStateType, null: true
    field :can_group, Boolean, null: true, method: :can_group?
    field :context_id, ID, null: false
    field :context_type, String, null: false
    field :delayed_post_at, Types::DateTimeType, null: true
    field :discussion_type, DiscussionTopicDiscussionType, null: true
    field :edited_at, Types::DateTimeType, null: true
    field :expanded, Boolean, null: true
    field :expanded_locked, Boolean, null: true
    field :is_announcement, Boolean, null: false
    field :is_anonymous_author, Boolean, null: true
    field :is_section_specific, Boolean, null: true
    field :last_reply_at, Types::DateTimeType, null: true
    field :lock_at, Types::DateTimeType, null: true
    field :locked, Boolean, null: false
    field :only_graders_can_rate, Boolean, null: true
    field :only_visible_to_overrides, Boolean, null: true
    field :podcast_enabled, Boolean, null: true
    field :podcast_has_student_posts, Boolean, null: true
    field :position, Int, null: true
    field :posted_at, Types::DateTimeType, null: true
    field :require_initial_post, Boolean, null: true
    field :sort_by_rating, Boolean, null: true
    field :sort_order_locked, Boolean, null: true
    field :title, String, null: true
    field :todo_date, GraphQL::Types::ISO8601DateTime, null: true
    field :visible_to_everyone, Boolean, null: true

    field :message, String, null: true
    def message
      # A discussion can be locked but still allow users to view the discussion
      # In these cases we want to return the discussion message, otherwise we want to
      # return the lock explanation
      locked_info = object.locked_for?(current_user, check_policies: true)
      if locked_info && !locked_info[:can_view]
        return lock_explanation(locked_info, "topic", object.context, { only_path: true, include_js: false })
      end

      Loaders::ApiContentAttachmentLoader.for(object.context).load(object.message).then do |preloaded_attachments|
        GraphQLHelpers::UserContent.process(object.message,
                                            request: context[:request],
                                            context: object.context,
                                            user: current_user,
                                            in_app: context[:in_app],
                                            preloaded_attachments:,
                                            options: {
                                              domain_root_account: context[:domain_root_account],
                                            },
                                            location: object.asset_string)
      end
    end

    field :lock_information, String, null: true
    def lock_information
      locked_info = object.locked_for?(current_user, check_policies: true)
      return nil unless locked_info

      lock_explanation(locked_info, "topic", object.context, { only_path: true, include_js: false })
    end

    field :available_for_user, Boolean, null: false
    def available_for_user
      locked_info = object.locked_for?(current_user, check_policies: true)
      if locked_info
        !locked_info[:unlock_at]
      else
        !locked_info
      end
    end

    field :user_count, Integer, null: true
    def user_count
      object.course.nil? ? 0 : object.course.enrollments.not_fake.active_or_pending_by_date_ignoring_access.distinct.count(:user_id)
    end

    field :initial_post_required_for_current_user, Boolean, null: false
    def initial_post_required_for_current_user
      object.initial_post_required?(current_user, session)
    end

    field :published, Boolean, null: false
    def published
      object.published?
    end

    field :points_possible, Float, null: true
    def points_possible
      object.try(:assignment).try(:points_possible)
    end

    field :reply_to_entry_required_count, Integer, null: false
    def reply_to_entry_required_count
      object.root_topic ? object.root_topic.reply_to_entry_required_count : object.reply_to_entry_required_count
    end

    field :submissions_connection, SubmissionType.connection_type, null: true do
      description "submissions for this assignment"
      argument :filter, SubmissionSearchFilterInputType, required: false
      argument :order_by, [SubmissionSearchOrderInputType], required: false
    end
    def submissions_connection(filter: nil, order_by: nil)
      return nil if current_user.nil? || object.assignment.nil?

      filter = filter.to_h
      order_by ||= []
      filter[:states] ||= DEFAULT_SUBMISSION_STATES
      filter[:states] = filter[:states] + ["unsubmitted"].freeze if filter[:include_unsubmitted]
      filter[:order_by] = order_by.map(&:to_h)
      SubmissionSearch.new(object.assignment, current_user, session, filter).search
    end

    field :checkpoints, [CheckpointType], "a list of checkpoints(also known as sub_assignments) that belong to this discussion", null: true
    def checkpoints
      load_association(:assignment).then do |assignment|
        if assignment&.context&.discussion_checkpoints_enabled?
          assignment.sub_assignments
        end
      end
    end

    field :assignment, Types::AssignmentType, null: true
    def assignment
      load_association(:assignment)
    end

    field :attachment, Types::FileType, null: true
    def attachment
      load_association(:attachment)
    end

    field :root_topic, Types::DiscussionType, null: true
    def root_topic
      load_association(:root_topic)
    end

    field :discussion_entries_connection, Types::DiscussionEntryType.connection_type, null: true do
      argument :filter, Types::DiscussionFilterType, required: false
      argument :root_entries, Boolean, required: false
      argument :search_term, String, required: false
      argument :unread_before, String, required: false
      argument :user_search_id, String, required: false
    end
    def discussion_entries_connection(**args)
      args.delete(:sort_order)
      get_entries(**args)
    end

    field :discussion_entry_drafts_connection, Types::DiscussionEntryDraftType.connection_type, null: true
    def discussion_entry_drafts_connection
      Loaders::DiscussionEntryDraftLoader.for(current_user:).load(object)
    end

    field :entry_counts, Types::DiscussionEntryCountsType, null: true
    def entry_counts
      Loaders::DiscussionEntryCountsLoader.for(current_user:).load(object)
    end

    field :subscribed, Boolean, null: false
    def subscribed
      load_association(:discussion_topic_participants).then do
        object.subscribed?(current_user)
      end
    end

    field :group_set, Types::GroupSetType, null: true
    def group_set
      load_association(:group_category)
    end

    field :child_topics, [Types::DiscussionType], null: true
    def child_topics
      load_association(:child_topics).then do |child_topics|
        Loaders::AssociationLoader.for(DiscussionTopic, :context).load_many(child_topics).then do
          child_topics = child_topics.select { |ct| ct.active? && ct.context.active? }
          child_topics.sort_by { |ct| ct.context.name }
        end
      end
    end

    field :context_name, String, null: true
    def context_name
      load_association(:context).then do |context|
        context&.name
      end
    end

    field :author, Types::UserType, null: true do
      argument :built_in_only, Boolean, "Only return default/built_in roles", required: false
      argument :course_id, String, required: false
      argument :role_types, [String], "Return only requested base role types", required: false
    end
    def author(course_id: nil, role_types: nil, built_in_only: false)
      # Conditionally set course_id based on whether it's provided or should be inferred from the object
      resolved_course_id = course_id.nil? ? object&.course&.id : course_id

      if object&.course.is_a?(Account) && !object&.group&.id.nil?
        context[:group_id] = object&.group&.id
      else
        # Set the graphql context so it can be used downstream
        context[:course_id] = resolved_course_id
      end

      if object.anonymous? && resolved_course_id.nil?
        nil
      else
        load_association(:user).then do |user|
          if !object.anonymous? || user.nil?
            user
          else
            Loaders::CourseRoleLoader.for(course_id: resolved_course_id, role_types:, built_in_only:).load(user).then do |roles|
              if roles&.include?("TeacherEnrollment") || roles&.include?("TaEnrollment") || roles&.include?("DesignerEnrollment") || (object.anonymous_state == "partial_anonymity" && !object.is_anonymous_author)
                user
              end
            end
          end
        end
      end
    end

    field :anonymous_author, Types::AnonymousUserType, null: true
    def anonymous_author
      if object.anonymous_state == "full_anonymity" || (object.anonymous_state == "partial_anonymity" && object.is_anonymous_author)
        Loaders::DiscussionTopicParticipantLoader.for(object.id).load(object.user_id).then do |participant|
          if participant.nil?
            nil
          else
            {
              id: participant.id.to_s(36),
              short_name: (object.user_id == current_user.id) ? "current_user" : participant.id.to_s(36),
              avatar_url: nil
            }
          end
        end
      else
        nil
      end
    end

    field :editor, Types::UserType, null: true do
      argument :built_in_only, Boolean, "Only return default/built_in roles", required: false
      argument :course_id, String, required: false
      argument :role_types, [String], "Return only requested base role types", required: false
    end
    def editor(course_id: nil, role_types: nil, built_in_only: false)
      # Conditionally set course_id based on whether it's provided or should be inferred from the object
      resolved_course_id = course_id.nil? ? object&.course&.id : course_id
      # Set the graphql context so it can be used downstream
      context[:course_id] = resolved_course_id
      if object.anonymous? && !resolved_course_id
        nil
      else
        load_association(:editor).then do |user|
          if !object.anonymous? || !user
            user
          else
            Loaders::CourseRoleLoader.for(course_id:, role_types:, built_in_only:).load(user).then do |roles|
              if roles&.include?("TeacherEnrollment") || roles&.include?("TaEnrollment") || roles&.include?("DesignerEnrollment") || (object.anonymous_state == "partial_anonymity" && !object.is_anonymous_author)
                user
              end
            end
          end
        end
      end
    end

    field :permissions, Types::DiscussionPermissionsType, null: true
    def permissions
      load_association(:context).then do
        {
          loader: Loaders::PermissionsLoader.for(object, current_user:, session:),
          discussion_topic: object
        }
      end
    end

    field :course_sections, [Types::SectionType], null: false
    def course_sections
      course = nil
      if object.context.is_a?(Course)
        course = object.context
      end

      if object.context.is_a?(Group) && object.context.context.is_a?(Course)
        course = object.context.context
      end

      load_association(:course_sections).then do |course_sections|
        if course.nil?
          course_sections
        else
          Loaders::CourseRoleLoader.for(course_id: course.id, role_types: nil, built_in_only: nil).load(current_user).then do |roles|
            if course.grants_right?(current_user, :update) || roles&.include?("TeacherEnrollment") || roles&.include?("TaEnrollment") || roles&.include?("DesignerEnrollment")
              course_sections
            else
              course_sections.joins(:student_enrollments).where(enrollments: { user_id: current_user.id })
            end
          end
        end
      end
    end

    field :can_unpublish, Boolean, null: false
    def can_unpublish
      object.can_unpublish?
    end

    field :can_reply_anonymously, Boolean, null: false
    def can_reply_anonymously
      return false unless object.context.is_a?(Course)

      Loaders::CourseRoleLoader.for(course_id: object.context.id, role_types: nil, built_in_only: nil).load(current_user).then do |roles|
        !(roles&.include?("TeacherEnrollment") || roles&.include?("TaEnrollment") || roles&.include?("DesignerEnrollment"))
      end
    end

    field :entries_total_pages, Integer, null: true do
      argument :filter, Types::DiscussionFilterType, required: false
      argument :per_page, Integer, required: true
      argument :root_entries, Boolean, required: false
      argument :search_term, String, required: false
      argument :sort_order, Types::DiscussionSortOrderType, required: false
      argument :unread_before, String, required: false
    end
    def entries_total_pages(**args)
      get_entry_page_count(**args)
    end

    field :root_entries_total_pages, Integer, null: true do
      argument :filter, Types::DiscussionFilterType, required: false
      argument :per_page, Integer, required: true
      argument :search_term, String, required: false
      argument :sort_order, Types::DiscussionSortOrderType, required: false
    end
    def root_entries_total_pages(**args)
      args[:root_entries] = true
      get_entry_page_count(**args)
    end

    def get_entry_page_count(**args)
      per_page = args.delete(:per_page)
      get_entries(**args).then do |entries|
        (entries.count.to_f / per_page).ceil
      end
    end

    field :search_entry_count, Integer, null: true do
      argument :filter, Types::DiscussionFilterType, required: false
      argument :search_term, String, required: false
    end
    def search_entry_count(**args)
      get_entries(**args).then(&:count)
    end

    field :mentionable_users_connection, Types::MessageableUserType.connection_type, null: true do
      argument :search_term, String, required: false
    end
    def mentionable_users_connection(search_term: nil)
      return nil if object.anonymous?

      Loaders::MentionableUserLoader.for(
        current_user:,
        search_term:
      ).load(object)
    end

    field :ungraded_discussion_overrides, Types::AssignmentOverrideType.connection_type, null: true
    def ungraded_discussion_overrides
      object.ungraded_discussion_overrides(current_user)
    end

    field :subscription_disabled_for_user, Boolean, null: true
    def subscription_disabled_for_user
      return false if object.is_announcement

      object.subscription_hold(current_user, session)
    end

    def get_entries(search_term: nil, filter: nil, root_entries: false, user_search_id: nil, unread_before: nil)
      return [] if object.initial_post_required?(current_user, session) || !available_for_user

      Loaders::DiscussionEntryLoader.for(
        current_user:,
        search_term:,
        filter:,
        sort_order: object.sort_order_for_user(current_user),
        root_entries:,
        user_search_id:,
        unread_before:
      ).load(object)
    end

    field :sort_order, Types::DiscussionSortOrderType, null: true do
      argument :sort, Types::DiscussionSortOrderType, required: false
    end

    def sort_order
      object.sanitized_sort_order.to_sym || DiscussionTopic::SortOrder::DEFAULT.to_sym
    end

    field :participant, Types::DiscussionParticipantType, null: true
    def participant
      object.participant(current_user) || object.update_or_create_participant(current_user:)
    end
  end
end
