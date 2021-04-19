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
  class ProgressStateType < BaseEnum
    graphql_name "ProgressState"
    value "queued"
    value "running"
    value "completed"
    value "failed"
  end

  class ProgressContextUnion < BaseUnion
    graphql_name "ProgressContext"

    possible_types AssignmentType, CourseType, FileType, GroupSetType, UserType
  end

  class ProgressType < ApplicationObjectType
    graphql_name "Progress"

    description "Returns completion status and progress information about an asynchronous job"

    alias progress object

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :context, ProgressContextUnion, null: true, resolver_method: :progress_context
    def progress_context
      load_association(:context).then do |context|
        # TODO: this can go away when graphql supports all types that a
        # progress context can be
        case context
        when Assignment, Course, Attachment, GroupCategory, User
          context
        else
          nil
        end
      end
    end

    field :tag, String, "the type of operation", null: false

    field :completion, Integer, "percent completed", null: true

    field :state, ProgressStateType, method: :workflow_state, null: false

    field :message, String, "details about the job", null:  true
  end
end
