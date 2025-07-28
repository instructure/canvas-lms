# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Types
  class AuditEventRoleType < Types::BaseEnum
    value "student"
    value "final_grader"
    value "admin"
    value "grader"
  end

  class AuditEventQuizType < ApplicationObjectType
    implements Interfaces::LegacyIDInterface

    field :name, String, null: false, hash_key: :title

    field :role, Types::AuditEventRoleType, null: false
    def role
      Types::AuditEventRoleType.values["grader"].value
    end
  end

  class AuditEventExternalToolType < ApplicationObjectType
    implements Interfaces::LegacyIDInterface

    field :name, String, null: false

    field :role, Types::AuditEventRoleType, null: false
    def role
      Types::AuditEventRoleType.values["grader"].value
    end
  end

  class AuditEventUserType < ApplicationObjectType
    implements Interfaces::LegacyIDInterface

    field :name, String, null: false

    field :role, Types::AuditEventRoleType, null: false
    def role
      user = object
      submission = context[:parent_submission]
      assignment = context[:assignment]

      AnonymousOrModerationEvent.auditing_user_role(user:, submission:, assignment:)
    end
  end

  class AuditEventTypeType < Types::BaseEnum
    AnonymousOrModerationEvent::EVENT_TYPES.each do |event_type|
      value event_type
    end
  end

  # This is the corresponding GraphQL type for the AnonymousOrModerationEvent model
  # IMPORTANT: The current submission is required for resolving the AuditEvent > User > Role field,
  # and as such, it needs to be passed down through the context. Although some AuditEvents may
  # have a `null` value for `submission_id`, these events are still included in the results
  # if their `assignment_id` matches. In this case, the calculation for the AuditEvent > User >
  # Role field relies on the current submission to determine the correct role, thus these types
  # do not implement the `Node` interface and cannot be loaded top-level!
  class AuditEventType < ApplicationObjectType
    implements Interfaces::LegacyIDInterface
    implements Interfaces::TimestampInterface

    field :event_type, Types::AuditEventTypeType, null: false
    field :payload, GraphQL::Types::JSON, null: true

    field :external_tool, Types::AuditEventExternalToolType, null: true
    def external_tool
      load_association(:context_external_tool)
    end

    field :quiz, Types::AuditEventQuizType, null: true
    def quiz
      load_association(:quiz)
    end

    field :user, Types::AuditEventUserType, null: true
    def user
      return nil unless object[:user_id]

      scoped_ctx = context.scoped

      Promise.all([load_association(:user), load_association(:assignment)]).then do |user, assignment|
        scoped_ctx.set!(:assignment, assignment)

        user
      end
    end
  end
end
