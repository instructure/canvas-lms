# @API Originality Reports
# @internal
#
# LTI API for Submissions
#
# @model Submission
#     {
#       "id": "Submission",
#       "description": "",
#       "properties": {
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
#           "description": "Files that are attached to the submission"
#           "type": "File"
#         }
#       }
#     }

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
module Lti
  class SubmissionsApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper
    include Api::V1::Submission

    SUBMISSION_SERVICE = 'vnd.Canvas.submission'
    SUBMISSION_HISTORY_SERVICE = 'vnd.Canvas.submission.history'

    SERVICE_DEFINITIONS = [
      {
        id: SUBMISSION_SERVICE,
        endpoint: 'api/lti/assignments/{:assignment_id}/subscriptions/{:subscription_id}',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }.freeze,
      {
        id: SUBMISSION_HISTORY_SERVICE,
        endpoint: 'api/lti/assignments/{:assignment_id}/subscriptions/{:subscription_id}/history',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }
    ].freeze

    skip_before_action :load_user
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

    private

    def submission
      @_submission ||= Submission.find(params[:submission_id])
    end

    def authorized?
      authed = PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: submission.assignment)
      authed &&= tool_proxy.enabled_capabilities.include?(ResourcePlacement::SIMILARITY_DETECTION_LTI2)
      render_unauthorized unless authed
    end

    def api_json(submission)
      submission_attributes = %w(id body url submitted_at assignment_id user_id submission_type workflow_state attempt attachments)
      attachment_attributes = %w(id display_name filename content-type url size created_at updated_at)
      sub_hash = filtered_json(model: submission, whitelist: submission_attributes)
      sub_hash[:user_id] = Lti::Asset.opaque_identifier_for(User.find(sub_hash[:user_id]))
      attachments = submission.versioned_attachments
      sub_hash[:attachments] = attachments.map { |a| filtered_json(model: a, whitelist: attachment_attributes) }
      sub_hash
    end

    def filtered_json(model:, whitelist:)
      model.as_json(include_root: false).select { |k, _| whitelist.include?(k) }
    end

  end
end
