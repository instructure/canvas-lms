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
  def self.field(*, **)
    super(*, **, extensions: [PostgresTimeoutFieldExtension, AuditLogFieldExtension])
  end

  field :add_conversation_message, mutation: Mutations::AddConversationMessage
  field :create_conversation, mutation: Mutations::CreateConversation
  field :create_group_in_set, mutation: Mutations::CreateGroupInSet
  field :create_group_set, mutation: Mutations::CreateGroupSet
  field :hide_assignment_grades, mutation: Mutations::HideAssignmentGrades
  field :hide_assignment_grades_for_sections, mutation: Mutations::HideAssignmentGradesForSections
  field :post_assignment_grades, mutation: Mutations::PostAssignmentGrades
  field :post_assignment_grades_for_sections, mutation: Mutations::PostAssignmentGradesForSections
  field :set_override_score, <<~MD, mutation: Mutations::SetOverrideScore
    Sets the overridden final score for the associated enrollment, optionally limited to a specific
    grading period. This will supersede the computed final score/grade if present.
  MD
  field :set_assignment_post_policy, <<~MD, mutation: Mutations::SetAssignmentPostPolicy
    Sets the post policy for the assignment.
  MD
  field :set_course_post_policy, <<~MD, mutation: Mutations::SetCoursePostPolicy
    Sets the post policy for the course, with an option to override and delete
    existing assignment post policies.
  MD
  field :create_assignment, mutation: Mutations::CreateAssignment
  field :create_comment_bank_item, mutation: Mutations::CreateCommentBankItem
  field :create_discussion_entry, mutation: Mutations::CreateDiscussionEntry
  field :create_discussion_entry_draft, mutation: Mutations::CreateDiscussionEntryDraft
  field :create_discussion_topic, mutation: Mutations::CreateDiscussionTopic
  field :create_internal_setting, mutation: Mutations::CreateInternalSetting
  field :create_learning_outcome, mutation: Mutations::CreateLearningOutcome
  field :create_learning_outcome_group, mutation: Mutations::CreateLearningOutcomeGroup
  field :create_module, mutation: Mutations::CreateModule
  field :create_outcome_calculation_method, mutation: Mutations::CreateOutcomeCalculationMethod
  field :create_outcome_proficiency, mutation: Mutations::CreateOutcomeProficiency
  field :create_submission_comment, mutation: Mutations::CreateSubmissionComment
  field :create_submission_draft, mutation: Mutations::CreateSubmissionDraft
  field :create_user_inbox_label, mutation: Mutations::CreateUserInboxLabel
  field :delete_comment_bank_item, mutation: Mutations::DeleteCommentBankItem
  field :delete_conversation_messages, mutation: Mutations::DeleteConversationMessages
  field :delete_conversations, mutation: Mutations::DeleteConversations
  field :delete_custom_grade_status, mutation: Mutations::DeleteCustomGradeStatus
  field :delete_discussion_entry, mutation: Mutations::DeleteDiscussionEntry
  field :delete_discussion_topic, mutation: Mutations::DeleteDiscussionTopic
  field :delete_internal_setting, mutation: Mutations::DeleteInternalSetting
  field :delete_outcome_calculation_method, mutation: Mutations::DeleteOutcomeCalculationMethod
  field :delete_outcome_links, mutation: Mutations::DeleteOutcomeLinks
  field :delete_outcome_proficiency, mutation: Mutations::DeleteOutcomeProficiency
  field :delete_submission_comment, mutation: Mutations::DeleteSubmissionComment
  field :delete_submission_draft, mutation: Mutations::DeleteSubmissionDraft
  field :delete_user_inbox_label, mutation: Mutations::DeleteUserInboxLabel
  field :import_outcomes, mutation: Mutations::ImportOutcomes
  field :mark_submission_comments_read, mutation: Mutations::MarkSubmissionCommentsRead
  field :move_outcome_links, mutation: Mutations::MoveOutcomeLinks
  field :post_draft_submission_comment, mutation: Mutations::PostDraftSubmissionComment
  field :save_rubric_assessment, mutation: Mutations::SaveRubricAssessment
  field :set_friendly_description, mutation: Mutations::SetFriendlyDescription
  field :set_module_item_completion, mutation: Mutations::SetModuleItemCompletion
  field :set_override_status, mutation: Mutations::SetOverrideStatus
  field :set_rubric_self_assessment, mutation: Mutations::SetRubricSelfAssessment
  field :subscribe_to_discussion_topic, mutation: Mutations::SubscribeToDiscussionTopic
  field :update_assignment, mutation: Mutations::UpdateAssignment
  field :update_comment_bank_item, mutation: Mutations::UpdateCommentBankItem
  field :update_conversation_participants, mutation: Mutations::UpdateConversationParticipants
  field :update_discussion_entries_read_state, mutation: Mutations::UpdateDiscussionEntriesReadState
  field :update_discussion_entry, mutation: Mutations::UpdateDiscussionEntry
  field :update_discussion_entry_participant, mutation: Mutations::UpdateDiscussionEntryParticipant
  field :update_discussion_expanded, mutation: Mutations::UpdateDiscussionExpanded
  field :update_discussion_read_state, mutation: Mutations::UpdateDiscussionReadState
  field :update_discussion_sort_order, mutation: Mutations::UpdateDiscussionSortOrder
  field :update_discussion_thread_read_state, mutation: Mutations::UpdateDiscussionThreadReadState
  field :update_discussion_topic, mutation: Mutations::UpdateDiscussionTopic
  field :update_discussion_topic_participant, mutation: Mutations::UpdateDiscussionTopicParticipant
  field :update_gradebook_group_filter, mutation: Mutations::UpdateGradebookGroupFilter
  field :update_internal_setting, mutation: Mutations::UpdateInternalSetting
  field :update_learning_outcome, mutation: Mutations::UpdateLearningOutcome
  field :update_learning_outcome_group, mutation: Mutations::UpdateLearningOutcomeGroup
  field :update_my_inbox_settings, mutation: Mutations::UpdateMyInboxSettings
  field :update_notification_preferences, mutation: Mutations::UpdateNotificationPreferences
  field :update_outcome_calculation_method, mutation: Mutations::UpdateOutcomeCalculationMethod
  field :update_outcome_proficiency, mutation: Mutations::UpdateOutcomeProficiency
  field :update_rubric_assessment_read_state, mutation: Mutations::UpdateRubricAssessmentReadState
  field :update_speed_grader_settings, mutation: Mutations::UpdateSpeedGraderSettings
  field :update_split_screen_view_deeply_nested_alert, mutation: Mutations::UpdateSplitScreenViewDeeplyNestedAlert
  field :update_submission_grade, mutation: Mutations::UpdateSubmissionGrade
  field :update_submission_grade_status, mutation: Mutations::UpdateSubmissionGradeStatus
  field :update_submission_sticker, mutation: Mutations::UpdateSubmissionSticker
  field :update_submission_student_entered_score, mutation: Mutations::UpdateSubmissionStudentEnteredScore
  field :update_submissions_read_state, mutation: Mutations::UpdateSubmissionsReadState
  field :update_user_discussions_splitscreen_view, mutation: Mutations::UpdateUserDiscussionsSplitscreenView
  field :upsert_custom_grade_status, mutation: Mutations::UpsertCustomGradeStatus
  field :upsert_standard_grade_status, mutation: Mutations::UpsertStandardGradeStatus

  # TODO: Remove the in active development string from here once this is more
  #       finalized.
  field :create_submission, <<~MD, mutation: Mutations::CreateSubmission
    IN ACTIVE DEVELOPMENT, USE AT YOUR OWN RISK: Submit homework on an assignment.
  MD

  field :auto_grade_submission, mutation: Mutations::AutoGradeSubmission
  field :update_rubric_archived_state, mutation: Mutations::UpdateRubricArchivedState
end
