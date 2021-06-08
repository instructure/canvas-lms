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
  class DiscussionEntryPermissionsType < ApplicationObjectType
    graphql_name "DiscussionEntryPermissions"

    field :read, Boolean, null: true
    def read
      object[:loader].load(:read)
    end

    field :reply, Boolean, null: true
    def reply
      object[:loader].load(:reply).then do |can_reply|
        can_reply && !object[:discussion_entry].deleted? && object[:discussion_entry].depth < 3
      end
    end

    field :update, Boolean, null: true
    def update
      object[:loader].load(:update)
    end

    field :delete, Boolean, null: true
    def delete
      object[:loader].load(:delete)
    end

    field :create, Boolean, null: true
    def create
      object[:loader].load(:create)
    end

    field :attach, Boolean, null: true
    def attach
      object[:loader].load(:attach)
    end

    field :rate, Boolean, null: true
    def rate
      object[:loader].load(:rate)
    end

    field :view_rating, Boolean, null: true
    def view_rating
      object[:discussion_entry].discussion_topic.allow_rating && !object[:discussion_entry].deleted?
    end

    field :speed_grader, Boolean, null: true
    def speed_grader
      topic = object[:discussion_entry].discussion_topic
      return false if topic.assignment_id.nil?

      Promise.all([
        Loaders::AssociationLoader.for(Course, :enrollment_term).load(topic.context),
        Loaders::AssociationLoader.for(DiscussionTopic, :assignment).load(topic)
      ]).then do
        small_roster_and_published = !topic.context.large_roster? && topic.assignment.published?
        course_permission_loader = Loaders::PermissionsLoader.for(topic.context, current_user: current_user, session: session)
        if topic.context.concluded?
          course_permission_loader.load(:read_as_admin).then do |read_as_admin|
            small_roster_and_published && read_as_admin
          end
        else
          course_permission_loader.load(:manage_grades).then do |manage_grades|
            course_permission_loader.load(:view_all_grades).then do |view_all_grades|
              small_roster_and_published && (manage_grades || view_all_grades)
            end
          end
        end
      end
    end
  end
end
