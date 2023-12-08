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

module Types
  class OnlineSubmissionType < Types::BaseEnum
    VALID_SUBMISSION_TYPES = %w[
      basic_lti_launch
      student_annotation
      media_recording
      online_text_entry
      online_upload
      online_url
    ].freeze

    graphql_name "OnlineSubmissionType"
    description "Types that can be submitted online"

    VALID_SUBMISSION_TYPES.each { |type| value(type) }
  end
end

class Mutations::CreateSubmission < Mutations::BaseMutation
  graphql_name "CreateSubmission"

  argument :annotatable_attachment_id,
           ID,
           required: false,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Attachment")
  argument :assignment_id,
           ID,
           required: true,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
  argument :body, String, required: false
  argument :file_ids,
           [ID],
           required: false,
           prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Attachment")
  argument :media_id, ID, required: false
  argument :resource_link_lookup_uuid, String, required: false
  argument :submission_type, Types::OnlineSubmissionType, required: true
  argument :url, String, required: false
  argument :student_id, ID, required: false

  field :submission, Types::SubmissionType, null: true

  def resolve(input:)
    assignment = Assignment.active.find(input[:assignment_id])
    assignment = assignment.overridden_for(current_user)
    context = assignment.context
    submission_type = input[:submission_type]

    InstStatsd::Statsd.increment("submission.graphql.create.proxy_submit") if input[:student_id].present?

    verify_authorized_action!(assignment, :read)
    if input[:student_id]
      verify_authorized_action!(assignment.course, :proxy_assignment_submission)
    else
      verify_authorized_action!(assignment, :submit)
    end

    submission_params = {
      annotatable_attachment_id: assignment.annotatable_attachment_id,
      attachments: [],
      body: "",
      require_submission_type_is_valid: true,
      submission_type:,
      url: nil
    }
    case submission_type
    when "basic_lti_launch"
      if input[:url].blank?
        return validation_error(I18n.t("LTI submissions require a URL to submit"))
      end

      submission_params[:url] = input[:url]
      submission_params[:resource_link_lookup_uuid] = input[:resource_link_lookup_uuid]
    when "student_annotation"
      if assignment.annotatable_attachment_id.blank?
        return(
          validation_error(
            I18n.t("Student Annotation submissions require an annotatable_attachment_id to submit")
          )
        )
      end
    when "media_recording"
      unless input[:media_id]
        return(
          validation_error(
            I18n.t(
              "%{media_recording} submissions require a %{media_id} to submit",
              { media_recording: "media_recording", media_id: "media_id" }
            )
          )
        )
      end
      media_object = MediaObject.by_media_id(input[:media_id]).first
      unless media_object
        return(
          validation_error(
            I18n.t(
              "The %{media_id} does not correspond to an existing media object",
              { media_id: "media_id" }
            )
          )
        )
      end
      submission_params[:media_comment_type] = media_object.media_type
      submission_params[:media_comment_id] = input[:media_id]
    when "online_text_entry"
      submission_params[:body] = input[:body]
    when "online_upload"
      owning_user = nil
      if input[:student_id]
        owning_user = assignment.submissions.find_by(user_id: input[:student_id])&.user
        submission_params[:proxied_student] = owning_user
      else
        owning_user = current_user
      end
      file_ids = (input[:file_ids] || []).compact.uniq
      error_files = []
      attachments = []
      file_ids.each do |file_id|
        attachment = Attachment.active.where(context_type: "User", context_id: owning_user&.id).find_by(id: file_id)
        attachment ||= Attachment.active.where(
          context_type: "Group",
          context_id: GroupMembership.where(workflow_state: "accepted", user_id: [owning_user&.id, owning_user&.global_id]).select(:group_id)
        ).find_by(id: file_id)

        if attachment
          attachments << attachment
        else
          error_files << file_id
        end
      end

      if error_files.present?
        return(
          validation_error(
            I18n.t(
              "No attachments found for the following ids: %{ids}",
              { ids: error_files }
            ),
            attribute: "file_ids"
          )
        )
      end

      upload_errors =
        validate_online_upload(assignment, attachments, is_proxy: !!input[:student_id])
      return upload_errors if upload_errors

      submission_params[:attachments] =
        Attachment.copy_attachments_to_submissions_folder(context, attachments)
    when "online_url"
      submission_params[:url] = input[:url]
    end

    submission = assignment.submit_homework(current_user, submission_params)
    { submission: }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  end

  private

  # TODO: move file validation to the model
  def validate_online_upload(assignment, attachments, is_proxy: false)
    if attachments.blank?
      return(
        validation_error(
          I18n.t("You must attach at least one file to this assignment"),
          attribute: "file_ids"
        )
      )
    end

    # Probably a superfluous check considering how we retrieve the attachments
    attachments.each { |attachment| verify_authorized_action!(attachment, :read) } unless is_proxy

    unless extensions_allowed?(assignment, attachments)
      validation_error(I18n.t("Invalid file type"), attribute: "file_ids")
    end
  end

  def extensions_allowed?(assignment, attachments)
    return true if assignment.allowed_extensions.blank?

    unless attachments.all? do |attachment|
             attachment_extension = attachment.after_extension || ""
             assignment.allowed_extensions.include?(attachment_extension.downcase)
           end
      return false
    end

    true
  end
end
