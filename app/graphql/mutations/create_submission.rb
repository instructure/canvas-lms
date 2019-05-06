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
  graphql_name 'OnlineSubmissionType'
  description 'Types that can be submitted online'
  value('online_upload')
end

class Mutations::CreateSubmission < Mutations::BaseMutation
  graphql_name 'CreateSubmission'

  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Assignment')
  argument :file_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('Attachment')
  argument :submission_type, OnlineSubmissionType, required: true

  field :submission, Types::SubmissionType, null: true

  def resolve(input:)
    assignment = Assignment.active.find(input[:assignment_id])
    assignment = assignment.overridden_for(current_user)
    context = assignment.context

    submission_type = input[:submission_type]
    file_ids = (input[:file_ids] || []).compact.uniq

    verify_authorized_action!(assignment, :read)
    verify_authorized_action!(assignment, :submit)

    attachments = current_user.attachments.active.where(id: file_ids)
    unless file_ids.size == attachments.size
      attachment_ids = attachments.map(&:id)
      return graphql_error(
        I18n.t(
          'No attachments found for the following ids: %{ids}',
          { ids: file_ids - attachment_ids.map(&:to_s) }
        )
      )
    end

    upload_errors = validate_online_upload(assignment, attachments) if submission_type == 'online_upload'
    return upload_errors if upload_errors

    submission_params = {
      body: 'Graphql dummy submission text entry',
      submission_type: submission_type
    }
    submission_params[:attachments] = copy_attachments_to_submissions_folder(context, attachments)

    submission = assignment.submit_homework(current_user, submission_params)
    {submission: submission}
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  rescue ActiveRecord::RecordInvalid => invalid
    errors_for(invalid.record)
  end

  private

  # TODO: move file validation to the model
  def validate_online_upload(assignment, attachments)
    return graphql_error(I18n.t('You must attach at least one file to this assignment')) if attachments.blank?

    # Probably a superfluous check considering how we retrieve the attachments
    attachments.each do |attachment|
      verify_authorized_action!(attachment, :read)
    end

    graphql_error(I18n.t('Invalid file type')) unless extensions_allowed?(assignment, attachments)
  end

  def extensions_allowed?(assignment, attachments)
    return true if assignment.allowed_extensions.blank?

    return false unless attachments.all? do |attachment|
      attachment_extension = attachment.after_extension || ''
      assignment.allowed_extensions.include?(attachment_extension.downcase)
    end

    true
  end

  def copy_attachments_to_submissions_folder(assignment_context, attachments)
    attachments.map do |attachment|
      if attachment&.folder&.for_submissions?
        attachment # already in a submissions folder
      elsif attachment.context.respond_to?(:submissions_folder)
        attachment.copy_to_folder!(attachment.context.submissions_folder(assignment_context))
      else
        attachment # in a weird context; leave it alone
      end
    end
  end

  def graphql_error(message)
    {
      errors: {
        message: message
      }
    }
  end
end
