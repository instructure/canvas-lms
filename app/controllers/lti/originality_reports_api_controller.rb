#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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

# @API Originality Reports
# @internal
#
# API for OriginalityReports
#
# Originality reports may be used by external tools providing plagiarism
# detection services to give an originality score to an assignment
# submission's file. An originality report has an associated
# file ID (the file submitted by the student) and an originality score
# between 0 and 100.
#
# @model OriginalityReport
#     {
#       "id": "OriginalityReport",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The id of the OriginalityReport",
#           "example": "4",
#           "type": "integer"
#         },
#         "file_id": {
#           "description": "The id of the file receiving the originality score",
#           "example": "8",
#           "type": "integer"
#         },
#         "originality_score": {
#           "description": "A number between 0 and 100 representing the originality score",
#           "example": "0.16",
#           "type": "number"
#         },
#         "originality_report_file_id": {
#           "description": "The ID of the file within Canvas containing the originality report document (if provided)",
#           "example": "23",
#           "type": "integer"
#         },
#         "originality_report_url": {
#           "description": "A non-LTI launch URL where the originality score of the file may be found.",
#           "example": "http://www.example.com/report",
#           "type": "string"
#         },
#         "originality_report_lti_url" :{
#           "description": "An LTI url where the originality score of the file may be found",
#           "example": "http://www.my-tool.com/report",
#           "type": "string"
#         }
#       }
#     }
module Lti
  class OriginalityReportsApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper

    ORIGINALITY_REPORT_SERVICE = 'vnd.Canvas.OriginalityReport'.freeze

    SERVICE_DEFINITIONS = [
      {
        id: ORIGINALITY_REPORT_SERVICE,
        endpoint: 'api/v1/assignments/{assignment_id}/submissions/{submission_id}/originality_report',
        format: ['application/json'].freeze,
        action: ['POST', 'PUT', 'GET'].freeze
      }.freeze
    ].freeze

    skip_before_action :load_user
    before_action :authorized_lti2_tool, :plagiarism_feature_flag_enabled
    before_action :attachment_in_context, only: [:create]
    before_action :report_in_context, only: [:update, :show]

    # @API Create an Originality Report
    # Create a new OriginalityReport for the specified file
    #
    # @argument originality_report[file_id] [Required, Integer]
    #   The id of the file being given an originality score.
    #
    # @argument originality_report[originality_score] [Required, Float]
    #   A number between 0 and 100 representing the measure of the
    #   specified file's originality.
    #
    # @argument originality_report[originality_report_url] [String]
    #   The URL where the originality report for the specified
    #   file may be found.
    #
    # @argument originality_report[originality_report_lti_url] [String]
    #   The URL of an LTI tool launch where the originality report of
    #   the specified file may be found. Takes precedence over
    #   originality_report_url in the Canvas UI.
    #
    # @argument originality_report[originality_report_file_id] [Integer]
    #    The ID of the file within Canvas that contains the originality
    #    report for the submitted file provided in the request URL.
    #
    # @returns OriginalityReport
    def create
      render_unauthorized_action and return unless tool_proxy_associated?
      report_attributes = params.require(:originality_report).permit(create_attributes).to_hash.merge(
        {submission_id: params.require(:submission_id)})

      @report = OriginalityReport.new(report_attributes)
      begin
        successful_save = @report.save
      rescue ActiveRecord::RecordNotUnique
        @report.errors.add(:base, I18n.t('the specified file with file_id already has an originality report'))
      end

      if successful_save
        render json: api_json(@report, @current_user, session), status: :created
      else
        render json: @report.errors, status: :bad_request
      end
    end

    # @API Edit an Originality Report
    # Modify an existing originality report
    #
    # @argument originality_report[originality_score] [Float]
    #   A number between 0 and 100 representing the measure of the
    #   specified file's originality.
    #
    # @argument originality_report[originality_report_url] [String]
    #   The URL where the originality report for the specified
    #   file may be found.
    #
    # @argument originality_report[originality_report_lti_url] [String]
    #   The URL of an LTI tool launch where the originality report of
    #   the specified file may be found. Takes precedent over
    #   originality_report_url in the Canvas UI.
    #
    # @argument originality_report[originality_report_file_id] [Integer]
    #    The ID of the file within Canvas that contains the originality
    #    report for the submitted file provided in the request URL.
    #
    # @returns OriginalityReport
    def update
      render_unauthorized_action and return unless tool_proxy_associated?
      if @report.update_attributes(params.require(:originality_report).permit(update_attributes))
        render json: api_json(@report, @current_user, session)
      else
        render json: @report.errors, status: :bad_request
      end
    end

    # @API Show an Originality ReportN
    # Get a single originality report
    #
    # @returns OriginalityReport
    def show
      render_unauthorized_action and return unless tool_proxy_associated?
      render json: api_json(@report, @current_user, session)
    end

    def lti2_service_name
      ORIGINALITY_REPORT_SERVICE
    end

    private

    def tool_proxy_associated?
      mh = assignment.tool_settings_tool
      mh.respond_to?(:resource_handler) && mh.resource_handler.tool_proxy.guid == access_token.sub
    end

    def plagiarism_feature_flag_enabled
      render_unauthorized_action unless assignment.context.root_account.feature_enabled?(:plagiarism_detection_platform)
    end

    def create_attributes
      [:originality_score,
       :file_id,
       :originality_report_file_id,
       :originality_report_url,
       :originality_report_lti_url].freeze
    end

    def update_attributes
      [:originality_report_file_id,
       :originality_report_url,
       :originality_report_lti_url,
       :originality_score,
       :workflow_state].freeze
    end

    def assignment
      @_assignment ||= Assignment.find(params[:assignment_id])
    end

    def attachment_in_context
      attachment = Attachment.find(params.require(:originality_report)[:file_id])
      submission = Submission.find(params[:submission_id])
      verify_submission_attachment(attachment, submission)
    end

    def report_in_context
      @report = OriginalityReport.find(params[:id])
      submission = Submission.find(params[:submission_id])
      verify_submission_attachment(@report.attachment, submission)
    end

    def verify_submission_attachment(attachment, submission)
      unless submission.assignment == assignment && submission.attachments.include?(attachment)
        head :unauthorized
      end
    end
  end
end
