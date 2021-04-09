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

class OnlineSubmissionType < Types::BaseEnum
  VALID_SUBMISSION_TYPES = %w[annotated_document media_recording online_text_entry online_upload online_url].freeze

  graphql_name 'OnlineSubmissionType'
  description 'Types that can be submitted online'

  VALID_SUBMISSION_TYPES.each { |type| value(type) }
end

class Mutations::CreateSubmission < Mutations::BaseMutation
  graphql_name 'CreateSubmission'

  argument :annotated_document_id,
           ID,
           required: false,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Attachment')
  argument :assignment_id,
           ID,
           required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Assignment')
  argument :body, String, required: false
  argument :file_ids,
           [ID],
           required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('Attachment')
  argument :media_id, ID, required: false
  argument :submission_type, OnlineSubmissionType, required: true
  argument :url, String, required: false

  field :submission, Types::SubmissionType, null: true

  def resolve(input:)
    assignment = Assignment.active.find(input[:assignment_id])
    assignment = assignment.overridden_for(current_user)
    context = assignment.context

    verify_authorized_action!(assignment, :read)
    verify_authorized_action!(assignment, :submit)

    submission_type = input[:submission_type]
    submission_params = {
      annotated_document_id: input[:annotated_document_id],
      attachments: [],
      body: '',
      require_submission_type_is_valid: true,
      submission_type: submission_type,
      url: nil
    }

    case submission_type
    when 'annotated_document'
      if input[:annotated_document_id].blank?
        return validation_error(I18n.t('Student Annotation submissions require an annotated_document_id to submit'))
      end
    when 'media_recording'
      unless input[:media_id]
        return(
          validation_error(
            I18n.t(
              '%{media_recording} submissions require a %{media_id} to submit',
              { media_recording: 'media_recording', media_id: 'media_id' }
            )
          )
        )
      end
      media_object = MediaObject.by_media_id(input[:media_id]).first
      unless media_object
        return(
          validation_error(
            I18n.t(
              'The %{media_id} does not correspond to an existing media object',
              { media_id: 'media_id' }
            )
          )
        )
      end
      submission_params[:media_comment_type] = media_object.media_type
      submission_params[:media_comment_id] = input[:media_id]
    when 'online_text_entry'
      submission_params[:body] = input[:body]
    when 'online_upload'
      file_ids = (input[:file_ids] || []).compact.uniq

      attachments = current_user.submittable_attachments.active.where(id: file_ids)
      unless file_ids.size == attachments.size
        attachment_ids = attachments.map(&:id)
        return(
          validation_error(
            I18n.t(
              'No attachments found for the following ids: %{ids}',
              { ids: file_ids - attachment_ids.map(&:to_s) }
            ),
            attribute: 'file_ids'
          )
        )
      end

      upload_errors = validate_online_upload(assignment, attachments)
      return upload_errors if upload_errors

      submission_params[:attachments] =
        Attachment.copy_attachments_to_submissions_folder(context, attachments)
    when 'online_url'
      submission_params[:url] = input[:url]
    end

    submission = assignment.submit_homework(current_user, submission_params)
    { submission: submission }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  rescue ActiveRecord::RecordInvalid => invalid
    errors_for(invalid.record)
  end

  private

  # TODO: move file validation to the model
  def validate_online_upload(assignment, attachments)
    if attachments.blank?
      return(
        validation_error(
          I18n.t('You must attach at least one file to this assignment'),
          attribute: 'file_ids'
        )
      )
    end

    # Probably a superfluous check considering how we retrieve the attachments
    attachments.each { |attachment| verify_authorized_action!(attachment, :read) }

    unless extensions_allowed?(assignment, attachments)
      validation_error(I18n.t('Invalid file type'), attribute: 'file_ids')
    end
  end

  def extensions_allowed?(assignment, attachments)
    return true if assignment.allowed_extensions.blank?

    unless attachments.all? do |attachment|
             attachment_extension = attachment.after_extension || ''
             assignment.allowed_extensions.include?(attachment_extension.downcase)
           end
      return false
    end

    true
  end
end
