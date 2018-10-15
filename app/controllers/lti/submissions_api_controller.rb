#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Lti
# @API Plagiarism Detection Submissions
# **LTI API for Plagiarism Detection Submissions (Must use <a href="jwt_access_tokens.html">JWT access tokens</a> with this API).**
#
# @model Submission
#     {
#       "id": "Submission",
#       "description": "",
#       "properties": {
#         "lti_course_id": {
#           "example": "66157096483e6b3a50bfedc6bac902c0b20a8241",
#           "type": "string"
#         },
#         "course_id": {
#           "example": 10000000000060,
#           "type": "integer"
#         },
#         "assignment_id": {
#           "description": "The submission's assignment id",
#           "example": 23,
#           "type": "integer"
#         },
#         "attempt": {
#           "description": "This is the submission attempt number.",
#           "example": 1,
#           "type": "integer"
#         },
#         "body": {
#           "description": "The content of the submission, if it was submitted directly in a text field.",
#           "example": "There are three factors too...",
#           "type": "string"
#         },
#         "submission_type": {
#           "description": "The types of submission ex: ('online_text_entry'|'online_url'|'online_upload'|'media_recording')",
#           "example": "online_text_entry",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "online_text_entry",
#               "online_url",
#               "online_upload",
#               "media_recording"
#             ]
#           }
#         },
#         "submitted_at": {
#           "description": "The timestamp when the assignment was submitted",
#           "example": "2012-01-01T01:00:00Z",
#           "type": "datetime"
#         },
#         "url": {
#           "description": "The URL of the submission (for 'online_url' submissions).",
#           "type": "string"
#         },
#         "user_id": {
#           "description": "The id of the user who created the submission",
#           "example": 134,
#           "type": "integer"
#         },
#         "eula_agreement_timestamp": {
#           "description": "UTC timestamp showing when the user agreed to the EULA (if given by the tool provider)",
#           "example": "1508250487578",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "The current state of the submission",
#           "example": "submitted",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "graded",
#               "submitted",
#               "unsubmitted",
#               "pending_review"
#             ]
#           }
#         },
#         "attachments": {
#           "description": "Files that are attached to the submission",
#           "type": "File"
#         }
#       }
#     }
#
# @model File
#     {
#       "id": "File",
#       "description": "",
#       "properties": {
#         "size": {
#           "example": 4,
#           "type": "integer"
#         },
#         "content-type": {
#           "example": "text/plain",
#           "type": "string"
#         },
#         "url": {
#           "example": "http://www.example.com/files/569/download?download_frd=1&verifier=c6HdZmxOZa0Fiin2cbvZeI8I5ry7yqD7RChQzb6P",
#           "type": "string"
#         },
#         "id": {
#           "example": 569,
#           "type": "integer"
#         },
#         "display_name": {
#           "example": "file.txt",
#           "type": "string"
#         },
#         "created_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         }
#       }
#     }
  class SubmissionsApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper
    include Api::V1::Submission
    include AttachmentHelper

    SUBMISSION_SERVICE = 'vnd.Canvas.submission'
    SUBMISSION_HISTORY_SERVICE = 'vnd.Canvas.submission.history'

    SERVICE_DEFINITIONS = [
      {
        id: SUBMISSION_SERVICE,
        endpoint: 'api/lti/assignments/{assignment_id}/submissions/{submission_id}',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }.freeze,
      {
        id: SUBMISSION_HISTORY_SERVICE,
        endpoint: 'api/lti/assignments/{assignment_id}/submissions/{submission_id}/history',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }.freeze
    ].freeze

    skip_before_action :load_user
    before_action :activate_tool_shard!, only: :attachment
    before_action :authorized_lti2_tool
    before_action :authorized?

    def lti2_service_name
      SUBMISSION_SERVICE
    end

    # @API Get a single submission
    #
    # Get a single submission, based on submission id.
    def show
      render json: api_json(submission)
    end

    # @API Get the history of a single submission
    #
    # Get a list of all attempts made for a submission, based on submission id.
    def history
      submissions = Submission.bulk_load_versioned_attachments(submission.submission_history)
      render json: submissions.map { |s| api_json(s) }
    end

    def attachment
      attachment = Attachment.find(params[:attachment_id])
      render_unauthorized and return unless attachment_for_submission?(attachment)
      render_or_redirect_to_stored_file(
        attachment: attachment)
    end


    def attachment_url(attachment)
      account = @domain_root_account || Account.default
      host, shard = HostUrl.file_host_with_shard(account, request.host_with_port)
      res = "#{request.protocol}#{host}"
      shard.activate do
        res + lti_submission_attachment_download_path(submission.assignment.global_id, submission.global_id, attachment.global_id)
      end
    end

    private

    def activate_tool_shard!
      render_unauthorized and return unless access_token
      tool_shard = Shard.lookup(access_token.shard_id)
      return if tool_shard == Shard.current
      tool_shard.activate!
    rescue Lti::Oauth2::InvalidTokenError
      render_unauthorized
    end

    def attachment_for_submission?(attachment)
      submissions = Submission.bulk_load_versioned_attachments(submission.submission_history + [submission])
      attachments = submissions.map { |s| s.versioned_attachments }.flatten
      attachments.include?(attachment)
    end

    def submission
      @_submission ||= Submission.active.find(params[:submission_id])
    end

    def authorized?
      authed = PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: submission.assignment)
      authed &&= tool_proxy.enabled_capabilities.include?(ResourcePlacement::SIMILARITY_DETECTION_LTI2)
      render_unauthorized unless authed
    end

    def api_json(submission)
      submission_attributes = %w(id body url submitted_at assignment_id user_id submission_type workflow_state attempt attachments)
      sub_hash = filtered_json(model: submission, whitelist: submission_attributes)
      sub_hash[:user_id] = Lti::Asset.opaque_identifier_for(User.find(sub_hash[:user_id]))
      if submission.turnitin_data[:eula_agreement_timestamp].present?
        sub_hash[:eula_agreement_timestamp] = submission.turnitin_data[:eula_agreement_timestamp]
      end
      attachments = submission.versioned_attachments
      sub_hash[:attachments] = attachments.map { |a| attachment_json(a) }
      sub_hash[:course_id] = submission.assignment.context.global_id
      sub_hash[:lti_course_id] = Lti::Asset.opaque_identifier_for(submission.assignment.context)
      sub_hash
    end

    def attachment_json(attachment)
      attachment_attributes = %w(id display_name filename content-type size created_at updated_at)
      attach = filtered_json(model: attachment, whitelist: attachment_attributes)
      attach[:url] = attachment_url(attachment)
      attach
    end

    def filtered_json(model:, whitelist:)
      model.as_json(include_root: false).select { |k, _| whitelist.include?(k) }
    end

  end
end
