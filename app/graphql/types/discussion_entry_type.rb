# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
  class DiscussionEntryType < ApplicationObjectType
    graphql_name "DiscussionEntry"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface
    global_id_field :id

    field :discussion_topic_id, ID, null: false
    field :parent_id, ID, null: true
    field :root_entry_id, ID, null: true
    field :rating_count, Integer, null: true
    field :rating_sum, Integer, null: true

    field :message, String, null: true
    def message
      if object.deleted?
        nil
      elsif object.message&.include?("instructure_inline_media_comment")
        load_association(:discussion_topic).then do |topic|
          Loaders::ApiContentAttachmentLoader.for(topic.context).load(object.message).then do |preloaded_attachments|
            GraphQLHelpers::UserContent.process(
              object.message,
              context: topic.context,
              in_app: true,
              request:,
              preloaded_attachments:,
              user: current_user,
              options: { rewrite_api_urls: true }
            )
          end
        end
      else
        object.message
      end
    end

    field :preview_message, String, null: true
    def preview_message
      object.deleted? ? nil : object.summary(ActiveRecord::Base.maximum_text_length)
    end

    field :quoted_entry, Types::DiscussionEntryType, null: true
    def quoted_entry
      if object.deleted?
        nil
      elsif object.quoted_entry_id
        load_association(:quoted_entry)
      end
    end

    field :author, Types::UserType, null: true do
      argument :course_id, String, required: false
      argument :role_types, [String], "Return only requested base role types", required: false
      argument :built_in_only, Boolean, "Only return default/built_in roles", required: false
    end
    def author(course_id: nil, role_types: nil, built_in_only: false)
      load_association(:discussion_topic).then do |topic|
        course_id = topic&.course&.id if course_id.nil?
        # Set the graphql context so it can be used downstream
        context[:course_id] = course_id
        if topic.anonymous? && object.is_anonymous_author
          nil
        else
          load_association(:user).then do |user|
            if !topic.anonymous? || !user
              user
            else
              Loaders::CourseRoleLoader.for(course_id:, role_types:, built_in_only:).load(user).then do |roles|
                if roles&.include?("TeacherEnrollment") || roles&.include?("TaEnrollment") || roles&.include?("DesignerEnrollment") || (topic.anonymous_state == "partial_anonymity" && !object.is_anonymous_author)
                  user
                end
              end
            end
          end
        end
      end
    end

    field :anonymous_author, Types::AnonymousUserType, null: true
    def anonymous_author
      load_association(:discussion_topic).then do |topic|
        if topic.anonymous_state == "full_anonymity" || (topic.anonymous_state == "partial_anonymity" && object.is_anonymous_author)
          Loaders::DiscussionTopicParticipantLoader.for(topic.id).load(object.user_id).then do |participant|
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
        end
      end
    end

    field :deleted, Boolean, null: true
    def deleted
      object.deleted?
    end

    field :editor, Types::UserType, null: true do
      argument :course_id, String, required: false
      argument :role_types, [String], "Return only requested base role types", required: false
      argument :built_in_only, Boolean, "Only return default/built_in roles", required: false
    end
    def editor(course_id: nil, role_types: nil, built_in_only: false)
      load_association(:discussion_topic).then do |topic|
        course_id = topic&.course&.id if course_id.nil?
        # Set the graphql context so it can be used downstream
        context[:course_id] = course_id
        if topic.anonymous? && !course_id
          nil
        else
          load_association(:editor).then do |user|
            if !topic.anonymous? || !user
              user
            else
              Loaders::CourseRoleLoader.for(course_id:, role_types:, built_in_only:).load(user).then do |roles|
                if roles&.include?("TeacherEnrollment") || roles&.include?("TaEnrollment") || roles&.include?("DesignerEnrollment") || (topic.anonymous_state == "partial_anonymity" && !object.is_anonymous_author)
                  user
                end
              end
            end
          end
        end
      end
    end

    field :root_entry_participant_counts, Types::DiscussionEntryCountsType, null: true
    def root_entry_participant_counts
      return nil unless object.root_entry_id.nil?

      Loaders::DiscussionEntryCountsLoader.for(current_user:).load(object)
    end

    field :discussion_topic, Types::DiscussionType, null: false
    def discussion_topic
      load_association(:discussion_topic)
    end

    field :discussion_subentries_connection, Types::DiscussionEntryType.connection_type, null: true do
      argument :sort_order, DiscussionSortOrderType, required: false
      argument :relative_entry_id, ID, required: false
      argument :before_relative_entry, Boolean, required: false
      argument :include_relative_entry, Boolean, required: false
    end
    def discussion_subentries_connection(sort_order: :asc, relative_entry_id: nil, before_relative_entry: true, include_relative_entry: true)
      Loaders::DiscussionEntryLoader.for(
        current_user:,
        sort_order:,
        relative_entry_id:,
        before_relative_entry:,
        include_relative_entry:
      ).load(object)
    end

    field :all_root_entries, [Types::DiscussionEntryType], null: true
    def all_root_entries
      return nil unless object.root_entry_id.nil?

      load_association(:flattened_discussion_subentries)
    end

    field :entry_participant, Types::EntryParticipantType, null: true
    def entry_participant
      Loaders::EntryParticipantLoader.for(
        current_user:
      ).load(object)
    end

    field :attachment, Types::FileType, null: true
    def attachment
      load_association(:attachment)
    end

    field :last_reply, Types::DiscussionEntryType, null: true
    def last_reply
      return nil unless object.root_entry_id.nil?

      load_association(:last_discussion_subentry)
    end

    field :subentries_count, Integer, null: true
    def subentries_count
      Loaders::AssociationCountLoader.for(DiscussionEntry, :discussion_subentries).load(object)
    end

    field :permissions, Types::DiscussionEntryPermissionsType, null: true
    def permissions
      load_association(:discussion_topic).then do
        {
          loader: Loaders::PermissionsLoader.for(object, current_user:, session:),
          discussion_entry: object
        }
      end
    end

    field :root_entry, Types::DiscussionEntryType, null: true
    def root_entry
      load_association(:root_entry)
    end

    field :discussion_entry_versions_connection, Types::DiscussionEntryVersionType.connection_type, null: true
    def discussion_entry_versions_connection
      is_course_teacher = object.context.is_a?(Course) && object.context.user_is_instructor?(current_user)
      is_group_teacher = object.context.is_a?(Group) && object.context&.course&.user_is_instructor?(current_user)
      return nil unless is_course_teacher || is_group_teacher || object.user == current_user

      if object.deleted?
        nil
      else
        load_association(:discussion_entry_versions)
      end
    end

    field :report_type_counts, Types::DiscussionEntryReportTypeCountsType, null: true
    def report_type_counts
      is_course_teacher = object.context.is_a?(Course) && object.context.user_is_instructor?(current_user)
      is_group_teacher = object.context.is_a?(Group) && object.context&.course&.user_is_instructor?(current_user)
      return nil unless is_course_teacher || is_group_teacher

      if object.deleted?
        nil
      else
        object.report_type_counts
      end
    end

    field :depth, Integer, null: true
    delegate :depth, to: :object
  end
end
