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

      Promise.all([
        Loaders::AssociationLoader.for(Course, :enrollment_term).load(object[:discussion_topic].context),
        Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(object[:discussion_topic])
      ]).then do
        permission = !object[:discussion_topic].context.large_roster? && object[:discussion_topic].assignment.published?
        course_permission_loader = Loaders::PermissionsLoader.for(object[:discussion_topic].context, current_user: current_user, session: session)
        if object[:discussion_topic].context.concluded?
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

    field :peer_review, Boolean, null: true
    def peer_review
      return false if object[:discussion_topic].assignment_id.nil?

      Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(object[:discussion_topic]).then do
        Loaders::PermissionsLoader.for(object[:discussion_topic].assignment, current_user: current_user, session: session).load(:grade).then do |can_grade|
          object[:discussion_topic].assignment.published? &&
          object[:discussion_topic].assignment.has_peer_reviews? &&
          can_grade
        end
      end
    end
  end
end
