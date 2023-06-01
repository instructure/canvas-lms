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
  class DiscussionPermissionsType < ApplicationObjectType
    graphql_name "DiscussionPermissions"

    field :read, Boolean, null: true
    def read
      object[:loader].load(:read)
    end

    field :read_replies, Boolean, null: true
    def read_replies
      object[:loader].load(:read_replies)
    end

    field :reply, Boolean, null: true
    def reply
      object[:loader].load(:reply)
    end

    field :student_reporting, Boolean, null: true
    def student_reporting
      object[:loader].load(:student_reporting)
    end

    field :update, Boolean, null: true
    def update
      object[:loader].load(:update)
    end

    field :delete, Boolean, null: true
    def delete
      object[:loader].load(:delete).then do |permission|
        permission && !object[:discussion_topic].editing_restricted?(:any)
      end
    end

    field :create, Boolean, null: true
    def create
      object[:loader].load(:create)
    end

    field :duplicate, Boolean, null: true
    def duplicate
      object[:loader].load(:duplicate)
    end

    field :attach, Boolean, null: true
    def attach
      object[:loader].load(:attach)
    end

    field :read_as_admin, Boolean, null: true
    def read_as_admin
      object[:loader].load(:read_as_admin)
    end

    field :manage_content, Boolean, null: true
    def manage_content
      Loaders::PermissionsLoader.for(
        object[:discussion_topic].context,
        current_user:,
        session:
      ).load(:manage_content)
    end

    field :manage_course_content_add, Boolean, null: true
    def manage_course_content_add
      Loaders::PermissionsLoader.for(
        object[:discussion_topic].context,
        current_user:,
        session:
      ).load(:manage_course_content_add)
    end

    field :manage_course_content_edit, Boolean, null: true
    def manage_course_content_edit
      Loaders::PermissionsLoader.for(
        object[:discussion_topic].context,
        current_user:,
        session:
      ).load(:manage_course_content_edit)
    end

    field :manage_course_content_delete, Boolean, null: true
    def manage_course_content_delete
      Loaders::PermissionsLoader.for(
        object[:discussion_topic].context,
        current_user:,
        session:
      ).load(:manage_course_content_delete)
    end

    field :rate, Boolean, null: true
    def rate
      object[:loader].load(:rate)
    end

    field :moderate_forum, Boolean, null: true
    def moderate_forum
      object[:loader].load(:moderate_forum)
    end

    field :speed_grader, Boolean, null: true
    def speed_grader
      return false if object[:discussion_topic].assignment_id.nil?

      Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(object[:discussion_topic]).then do
        Loaders::AssociationLoader.for(Assignment, :context).load(object[:discussion_topic].assignment).then do
          Loaders::AssociationLoader.for(Course, :enrollment_term).load(object[:discussion_topic].assignment.context).then do
            permission = !object[:discussion_topic].assignment.context.large_roster? && object[:discussion_topic].assignment.published?
            course_permission_loader = Loaders::PermissionsLoader.for(object[:discussion_topic].assignment.context, current_user:, session:)
            if object[:discussion_topic].assignment.context.concluded?
              course_permission_loader.load(:read_as_admin).then do |read_as_admin|
                permission && read_as_admin
              end
            else
              course_permission_loader.load(:manage_grades).then do |manage_grades|
                course_permission_loader.load(:view_all_grades).then do |view_all_grades|
                  permission && (manage_grades || view_all_grades)
                end
              end
            end
          end
        end
      end
    end

    field :peer_review, Boolean, null: true
    def peer_review
      return false if object[:discussion_topic].assignment_id.nil?

      Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(object[:discussion_topic]).then do
        Loaders::PermissionsLoader.for(object[:discussion_topic].assignment, current_user:, session:).load(:grade).then do |can_grade|
          object[:discussion_topic].assignment.published? &&
            object[:discussion_topic].assignment.has_peer_reviews? &&
            can_grade
        end
      end
    end

    field :show_rubric, Boolean, null: true
    def show_rubric
      return false if object[:discussion_topic].assignment_id.nil?

      Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(object[:discussion_topic]).then do |assignment|
        Loaders::AssociationLoader.for(Assignment, :rubric).load(assignment).then do |rubric|
          !rubric.nil?
        end
      end
    end

    field :add_rubric, Boolean, null: true
    def add_rubric
      return false if object[:discussion_topic].assignment_id.nil?

      Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(object[:discussion_topic]).then do |assignment|
        Loaders::AssociationLoader.for(Assignment, :rubric).load(assignment).then do |rubric|
          Loaders::PermissionsLoader.for(assignment, current_user:, session:).load(:update).then do |can_add_rubric|
            rubric.nil? && can_add_rubric
          end
        end
      end
    end

    field :open_for_comments, Boolean, null: true
    def open_for_comments
      return false if object[:discussion_topic].comments_disabled?
      return false unless object[:discussion_topic].locked

      object[:loader].load(:moderate_forum).then do |can_moderate|
        can_moderate
      end
    end

    field :close_for_comments, Boolean, null: true
    def close_for_comments
      return false if object[:discussion_topic].comments_disabled?
      return false if object[:discussion_topic].locked

      object[:loader].load(:moderate_forum).then do |can_moderate|
        if object[:discussion_topic].assignment_id.nil?
          can_moderate
        else
          Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(object[:discussion_topic]).then do
            object[:discussion_topic].can_lock? && can_moderate
          end
        end
      end
    end

    field :copy_and_send_to, Boolean, null: true
    def copy_and_send_to
      Loaders::PermissionsLoader.for(object[:discussion_topic].context, current_user:, session:).load(:read_as_admin)
    end
  end
end
