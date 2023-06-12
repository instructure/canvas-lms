# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class SubmissionError < StandardError
end

class Mutations::CreateSubmissionDraft < Mutations::BaseMutation
  graphql_name "CreateSubmissionDraft"

  # The attempt is passed in to prevent a possible race condition where a draft
  # could be created at the same time that an assignment was submitted, which
  # could lead to having a draft for an already submitted assignment. By
  # specifying the attempt, if that race condition does ever happen it will
  # create the `SubmissionDraft` for an old attempt and not return it back in
  # subsequent graphql queries for submission drafts.
  argument :active_submission_type, Types::DraftableSubmissionType, required: true
  argument :attempt, Integer, required: false
  argument :body, String, required: false
  argument :external_tool_id, ID, required: false
  argument :file_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Attachment")
  argument :lti_launch_url, String, required: false
  argument :media_id, ID, required: false
  argument :resource_link_lookup_uuid, String, required: false
  argument :submission_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Submission")
  argument :url, String, required: false

  field :submission_draft, Types::SubmissionDraftType, null: true

  def resolve(input:)
    @retried ||= false

    submission = find_submission(input[:submission_id])

    file_ids = (input[:file_ids] || []).compact.uniq
    attachments = get_and_verify_attachments!(file_ids)
    verify_allowed_extensions!(submission.assignment, attachments)

    submission_draft = SubmissionDraft.where(
      submission:,
      submission_attempt: input[:attempt] || (submission.attempt + 1)
    ).first_or_create!

    # TODO: we should research if we should split this mutation into a separate
    #       mutation for each draft type. the primary concern is the confusion
    #       of ignoring potentially included input types if they don't match
    #       the active submission.
    submission_draft.active_submission_type = input[:active_submission_type]
    case input[:active_submission_type]
    when "basic_lti_launch"
      raise SubmissionError if input[:lti_launch_url].blank? || input[:external_tool_id].blank?

      external_tool = ContextExternalTool.find_external_tool(
        input[:lti_launch_url],
        submission.course,
        input[:external_tool_id]
      )
      raise SubmissionError, I18n.t("no matching external tool found") if external_tool.blank?

      submission_draft.context_external_tool_id = external_tool.id
      submission_draft.lti_launch_url = input[:lti_launch_url]
      submission_draft.resource_link_lookup_uuid = input[:resource_link_lookup_uuid]
    when "media_recording"
      submission_draft.media_object_id = input[:media_id]
    when "online_text_entry"
      submission_draft.body = input[:body]
    when "online_upload"
      submission_draft.attachments = attachments
    when "online_url"
      submission_draft.url = input[:url]
    end

    submission_draft.save!

    { submission_draft: }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue ActiveRecord::RecordInvalid => e
    # activerecord validation is not robust to race condition
    #   multiple concurrent requests may penetrate activerecord validations
    #   and save dup records for a combination of submission_id and attempt
    # If it happened, following saves will be blocked by activerecord validation
    # Ideally, an unique index should be defined, but with many existing records,
    #   creating unique index may fail without cleaning data first.
    if submission_draft.present?
      submission_drafts = SubmissionDraft.where(
        submission: submission_draft.submission,
        submission_attempt: submission_draft.submission_attempt
      )
      if submission_drafts.count > 1 && !@retried
        @retried = true
        submission_drafts.where.not(id: submission_draft.id).destroy_all
        retry
      end
    end
    errors_for(e.record)
  rescue SubmissionError => e
    validation_error(e.message)
  end

  def self.submission_draft_log_entry(draft, _ctx)
    draft.submission
  end
end

private

def find_submission(submission_id)
  submission = Submission.active.find(submission_id)
  verify_authorized_action!(submission, :read)
  verify_authorized_action!(submission, :submit)
  submission
end

def get_and_verify_attachments!(file_ids)
  submittable_attachments = current_user.submittable_attachments do |scope|
    scope.left_joins(:replaced_attachments)
  end

  attachments = submittable_attachments.where(id: file_ids).or(
    # table alias for self-referencing relations is <relation_name>_<table_name>
    submittable_attachments.where(replaced_attachments_attachments: { id: file_ids })
  )

  validate_file_ids!(file_ids, attachments)
  attachments = attachments.to_a.uniq

  attachments.each do |attachment|
    verify_authorized_action!(attachment, :read)
  end

  attachments
end

def validate_file_ids!(file_ids, attachments)
  current_and_replaced_ids =
    attachments
    .pluck(:id, "replaced_attachments_attachments.id")
    .each_with_object(Set.new) do |(id, replaced_id), ids|
      ids << id.to_s
      ids << replaced_id.to_s if replaced_id
    end

  file_ids.each do |file_id|
    next if current_and_replaced_ids.include?(file_id)

    raise SubmissionError, I18n.t(
      "No attachments found for the following ids: %{ids}",
      { ids: file_ids - current_and_replaced_ids.to_a }
    )
  end
end

# TODO: move this into the model
def verify_allowed_extensions!(assignment, attachments)
  return if assignment.allowed_extensions.blank?

  raise SubmissionError, I18n.t("Invalid file type") unless attachments.all? do |attachment|
    attachment_extension = attachment.after_extension || ""
    assignment.allowed_extensions.include?(attachment_extension.downcase)
  end
end
