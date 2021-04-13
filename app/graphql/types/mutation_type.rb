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

class PostgresTimeoutFieldExtension < GraphQL::Schema::FieldExtension
  def resolve(object:, arguments:, context:, **rest)
    GraphQLPostgresTimeout.wrap(context.query) do
      yield(object, arguments)
    end
  rescue GraphQLPostgresTimeout::Error
    raise GraphQL::ExecutionError, "operation timed out"
  end
end

class Types::MutationType < Types::ApplicationObjectType
  graphql_name "Mutation"

  ##
  # wraps all mutation fields with necessary
  # extensions (e.g. pg timeout)
  def self.field(*args, **kwargs)
    super(*args, **kwargs, extensions: [PostgresTimeoutFieldExtension, AuditLogFieldExtension])
  end

  field :add_conversation_message, mutation: Mutations::AddConversationMessage
  field :create_conversation, mutation: Mutations::CreateConversation
  field :create_group_in_set, mutation: Mutations::CreateGroupInSet
  field :hide_assignment_grades, mutation: Mutations::HideAssignmentGrades
  field :hide_assignment_grades_for_sections, mutation: Mutations::HideAssignmentGradesForSections
  field :post_assignment_grades, mutation: Mutations::PostAssignmentGrades
  field :post_assignment_grades_for_sections, mutation: Mutations::PostAssignmentGradesForSections
  field :set_override_score, <<~DESC, mutation: Mutations::SetOverrideScore
    Sets the overridden final score for the associated enrollment, optionally limited to a specific
    grading period. This will supersede the computed final score/grade if present.
  DESC
  field :set_assignment_post_policy, <<~DESC, mutation: Mutations::SetAssignmentPostPolicy
    Sets the post policy for the assignment.
  DESC
  field :set_course_post_policy, <<~DESC, mutation: Mutations::SetCoursePostPolicy
    Sets the post policy for the course, with an option to override and delete
    existing assignment post policies.
  DESC
  field :create_outcome_proficiency, mutation: Mutations::CreateOutcomeProficiency
  field :update_outcome_proficiency, mutation: Mutations::UpdateOutcomeProficiency
  field :delete_outcome_proficiency, mutation: Mutations::DeleteOutcomeProficiency
  field :create_outcome_calculation_method, mutation: Mutations::CreateOutcomeCalculationMethod
  field :update_outcome_calculation_method, mutation: Mutations::UpdateOutcomeCalculationMethod
  field :delete_outcome_calculation_method, mutation: Mutations::DeleteOutcomeCalculationMethod
  field :create_assignment, mutation: Mutations::CreateAssignment
  field :update_assignment, mutation: Mutations::UpdateAssignment
  field :mark_submission_comments_read, mutation: Mutations::MarkSubmissionCommentsRead
  field :create_submission_comment, mutation: Mutations::CreateSubmissionComment
  field :create_submission_draft, mutation: Mutations::CreateSubmissionDraft
  field :create_module, mutation: Mutations::CreateModule
  field :update_notification_preferences, mutation: Mutations::UpdateNotificationPreferences
  field :delete_conversation_messages, mutation: Mutations::DeleteConversationMessages
  field :delete_conversations, mutation: Mutations::DeleteConversations
  field :delete_discussion_entry, mutation: Mutations::DeleteDiscussionEntry
  field :delete_discussion_topic, mutation: Mutations::DeleteDiscussionTopic
  field :update_conversation_participants, mutation: Mutations::UpdateConversationParticipants
  field :set_module_item_completion, mutation: Mutations::SetModuleItemCompletion
  field :update_discussion_topic, mutation: Mutations::UpdateDiscussionTopic
  field :subscribe_to_discussion_topic, mutation: Mutations::SubscribeToDiscussionTopic
  field :update_discussion_read_state, mutation: Mutations::UpdateDiscussionReadState
  field :create_discussion_entry, mutation: Mutations::CreateDiscussionEntry
  field :update_discussion_entry, mutation: Mutations::UpdateDiscussionEntry
  field :update_discussion_entry_participant, mutation: Mutations::UpdateDiscussionEntryParticipant

  # TODO: Remove the in active development string from here once this is more
  #       finalized.
  field :create_submission, <<~DESC, mutation: Mutations::CreateSubmission
    IN ACTIVE DEVELOPMENT, USE AT YOUR OWN RISK: Submit homework on an assignment.
  DESC
end
