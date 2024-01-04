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
  def resolve(object:, arguments:, context:, **)
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
  field :set_override_score, <<~MD, mutation: Mutations::SetOverrideScore
    Sets the overridden final score for the associated enrollment, optionally limited to a specific
    grading period. This will supersede the computed final score/grade if present.
  MD
  field :set_override_status, mutation: Mutations::SetOverrideStatus
  field :set_assignment_post_policy, <<~MD, mutation: Mutations::SetAssignmentPostPolicy
    Sets the post policy for the assignment.
  MD
  field :set_course_post_policy, <<~MD, mutation: Mutations::SetCoursePostPolicy
    Sets the post policy for the course, with an option to override and delete
    existing assignment post policies.
  MD
  field :create_learning_outcome, mutation: Mutations::CreateLearningOutcome
  field :update_learning_outcome, mutation: Mutations::UpdateLearningOutcome
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
  field :delete_submission_draft, mutation: Mutations::DeleteSubmissionDraft
  field :create_module, mutation: Mutations::CreateModule
  field :update_notification_preferences, mutation: Mutations::UpdateNotificationPreferences
  field :delete_conversation_messages, mutation: Mutations::DeleteConversationMessages
  field :delete_conversations, mutation: Mutations::DeleteConversations
  field :delete_discussion_entry, mutation: Mutations::DeleteDiscussionEntry
  field :delete_discussion_topic, mutation: Mutations::DeleteDiscussionTopic
  field :update_conversation_participants, mutation: Mutations::UpdateConversationParticipants
  field :set_module_item_completion, mutation: Mutations::SetModuleItemCompletion
  field :create_discussion_topic, mutation: Mutations::CreateDiscussionTopic
  field :update_discussion_topic, mutation: Mutations::UpdateDiscussionTopic
  field :subscribe_to_discussion_topic, mutation: Mutations::SubscribeToDiscussionTopic
  field :update_discussion_read_state, mutation: Mutations::UpdateDiscussionReadState
  field :update_discussion_entries_read_state, mutation: Mutations::UpdateDiscussionEntriesReadState
  field :create_discussion_entry, mutation: Mutations::CreateDiscussionEntry
  field :create_discussion_entry_draft, mutation: Mutations::CreateDiscussionEntryDraft
  field :update_discussion_entry, mutation: Mutations::UpdateDiscussionEntry
  field :update_discussion_thread_read_state, mutation: Mutations::UpdateDiscussionThreadReadState
  field :update_discussion_entry_participant, mutation: Mutations::UpdateDiscussionEntryParticipant
  field :import_outcomes, mutation: Mutations::ImportOutcomes
  field :set_friendly_description, mutation: Mutations::SetFriendlyDescription
  field :create_comment_bank_item, mutation: Mutations::CreateCommentBankItem
  field :delete_comment_bank_item, mutation: Mutations::DeleteCommentBankItem
  field :update_comment_bank_item, mutation: Mutations::UpdateCommentBankItem
  field :move_outcome_links, mutation: Mutations::MoveOutcomeLinks
  field :delete_outcome_links, mutation: Mutations::DeleteOutcomeLinks
  field :update_learning_outcome_group, mutation: Mutations::UpdateLearningOutcomeGroup
  field :create_learning_outcome_group, mutation: Mutations::CreateLearningOutcomeGroup
  field :update_split_screen_view_deeply_nested_alert, mutation: Mutations::UpdateSplitScreenViewDeeplyNestedAlert
  field :create_internal_setting, mutation: Mutations::CreateInternalSetting
  field :update_internal_setting, mutation: Mutations::UpdateInternalSetting
  field :delete_internal_setting, mutation: Mutations::DeleteInternalSetting
  field :update_rubric_assessment_read_state, mutation: Mutations::UpdateRubricAssessmentReadState
  field :update_submission_student_entered_score, mutation: Mutations::UpdateSubmissionStudentEnteredScore
  field :update_submissions_read_state, mutation: Mutations::UpdateSubmissionsReadState
  field :update_submission_grade, mutation: Mutations::UpdateSubmissionGrade
  field :update_user_discussions_splitscreen_view, mutation: Mutations::UpdateUserDiscussionsSplitscreenView
  field :upsert_custom_grade_status, mutation: Mutations::UpsertCustomGradeStatus
  field :upsert_standard_grade_status, mutation: Mutations::UpsertStandardGradeStatus
  field :delete_custom_grade_status, mutation: Mutations::DeleteCustomGradeStatus
  field :create_user_inbox_label, mutation: Mutations::CreateUserInboxLabel
  field :delete_user_inbox_label, mutation: Mutations::DeleteUserInboxLabel

  # TODO: Remove the in active development string from here once this is more
  #       finalized.
  field :create_submission, <<~MD, mutation: Mutations::CreateSubmission
    IN ACTIVE DEVELOPMENT, USE AT YOUR OWN RISK: Submit homework on an assignment.
  MD

  field :update_rubric_archived_state, mutation: Mutations::UpdateRubricArchivedState
end
