# frozen_string_literal: true

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
#

module Lti
  # @API Originality Reports
  # **LTI API for OriginalityReports (Must use <a href="jwt_access_tokens.html">JWT access tokens</a> with this API).**
  #
  # Originality reports may be used by external tools providing plagiarism
  # detection services to give an originality score to an assignment
  # submission's file. An originality report has an associated
  # file ID (the file submitted by the student) and an originality score
  # between 0 and 100.
  #
  # Note that when creating or updating an originality report a
  # `tool_setting[resource_type_code]` may be specified as part of the originality report.
  # This parameter should be used if the tool provider wishes to display
  # originality reports as LTI launches.
  #
  # The value of `tool_setting[resource_type_code]` should be a
  # resource_handler's "resource_type" code. Canvas will lookup the resource
  # handler specified and do a launch to the message with the type
  # "basic-lti-launch-request" using its "path". If the optional
  # `tool_setting[resource_url]` parameter is provided, Canvas
  # will use this URL instead of the message's `path` but will
  # still send all the parameters specified by the message. When using the
  # `tool_setting[resource_url]` the `tool_setting[resource_type_code]` must also be
  # specified.
  #
  # @model ToolSetting
  #     {
  #       "id": "ToolSetting",
  #       "description": "",
  #       "properties": {
  #          "resource_type_code": {
  #            "description": "the resource type code of the resource handler to use to display originality reports",
  #            "example": "originality_reports",
  #            "type": "string"
  #          },
  #          "resource_url": {
  #            "description": "a URL that may be used to override the launch URL inferred by the specified resource_type_code. If used a 'resource_type_code' must also be specified.",
  #            "example": "http://www.test.com/originality_report",
  #            "type": "string"
  #          }
  #       }
  #     }
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
  #         "tool_setting": {
  #            "description": "A ToolSetting object containing optional 'resource_type_code' and 'resource_url'",
  #            "$ref": "ToolSetting"
  #         },
  #         "error_report": {
  #            "description": "A message describing the error. If set, the workflow_state will become 'error.'",
  #            "type": "string"
  #         },
  #         "submission_time": {
  #            "description": "The submitted_at date time of the submission.",
  #            "type": "datetime"
  #         },
  #         "root_account_id": {
  #            "description": "The id of the root Account associated with the OriginalityReport",
  #            "example": "1",
  #            "type": "integer"
  #         }
  #       }
  #     }
  class OriginalityReportsApiController < ApplicationController
    include Lti::IMS::AccessTokenHelper

    ORIGINALITY_REPORT_SERVICE = "vnd.Canvas.OriginalityReport"

    SERVICE_DEFINITIONS = [
      {
        id: ORIGINALITY_REPORT_SERVICE,
        endpoint: "api/lti/assignments/{assignment_id}/submissions/{submission_id}/originality_report",
        format: ["application/json"].freeze,
        action: %w[POST PUT GET].freeze
      }.freeze
    ].freeze

    skip_before_action :load_user
    skip_before_action :verify_authenticity_token
    before_action :authorized_lti2_tool
    before_action :attachment_in_context, only: [:create]
    before_action :find_originality_report
    before_action :report_in_context, only: [:show, :update]
    before_action :ensure_tool_proxy_associated

    # NOTE
    # The LTI 2/Live Events plagiarism detection platform lives
    # alongside two other plagiarism solutions:
    # the Vericite plugin and the Turnitin plugin. When making changes
    # to any of these three services verify no regressions are
    # introduced in the others.

    # @API Create an Originality Report
    # Create a new OriginalityReport for the specified file
    #
    # @argument originality_report[file_id] [Integer]
    #   The id of the file being given an originality score. Required
    #   if creating a report associated with a file.
    #
    # @argument originality_report[originality_score] [Required, Float]
    #   A number between 0 and 100 representing the measure of the
    #   specified file's originality.
    #
    # @argument originality_report[originality_report_url] [String]
    #   The URL where the originality report for the specified
    #   file may be found.
    #
    # @argument originality_report[originality_report_file_id] [Integer]
    #    The ID of the file within Canvas that contains the originality
    #    report for the submitted file provided in the request URL.
    #
    # @argument originality_report[tool_setting][resource_type_code] [String]
    #   The resource type code of the resource handler Canvas should use for the
    #   LTI launch for viewing originality reports. If set Canvas will launch
    #   to the message with type 'basic-lti-launch-request' in the specified
    #   resource handler rather than using the originality_report_url.
    #
    # @argument originality_report[tool_setting][resource_url] [String]
    #   The URL Canvas should launch to when showing an LTI originality report.
    #   Note that this value is inferred from the specified resource handler's
    #   message "path" value (See `resource_type_code`) unless
    #   it is specified. If this parameter is used a `resource_type_code`
    #   must also be specified.
    #
    # @argument originality_report[workflow_state] [String]
    #   May be set to "pending", "error", or "scored". If an originality score
    #   is provided a workflow state of "scored" will be inferred.
    #
    # @argument originality_report[error_message] [String]
    #   A message describing the error. If set, the "workflow_state"
    #   will be set to "error."
    #
    # @argument originality_report[attempt] [Integer]
    #   If no `file_id` is given, and no file is required for the assignment
    #   (that is, the assignment allows an online text entry), this parameter
    #   may be given to clarify which attempt number the report is for (in the
    #   case of resubmissions). If this field is omitted and no `file_id` is
    #   given, the report will be created (or updated, if it exists) for the
    #   first submission attempt with no associated file.
    #
    # @returns OriginalityReport
    def create
      if @report.present?
        update
      else
        @report = OriginalityReport.new(create_report_params)
        if @report.save
          @report.copy_to_group_submissions_later!
          render json: api_json(@report, @current_user, session), status: :created
        else
          render json: @report.errors, status: :bad_request
        end
      end
    rescue StandError => e
      puts e.message
    end

    # @API Edit an Originality Report
    # Modify an existing originality report. An alternative to this endpoint is
    # to POST the same parameters listed below to the CREATE endpoint.
    #
    # @argument originality_report[originality_score] [Float]
    #   A number between 0 and 100 representing the measure of the
    #   specified file's originality.
    #
    # @argument originality_report[originality_report_url] [String]
    #   The URL where the originality report for the specified
    #   file may be found.
    #
    # @argument originality_report[originality_report_file_id] [Integer]
    #    The ID of the file within Canvas that contains the originality
    #    report for the submitted file provided in the request URL.
    #
    # @argument originality_report[tool_setting][resource_type_code] [String]
    #   The resource type code of the resource handler Canvas should use for the
    #   LTI launch for viewing originality reports. If set Canvas will launch
    #   to the message with type 'basic-lti-launch-request' in the specified
    #   resource handler rather than using the originality_report_url.
    #
    # @argument originality_report[tool_setting][resource_url] [String]
    #   The URL Canvas should launch to when showing an LTI originality report.
    #   Note that this value is inferred from the specified resource handler's
    #   message "path" value (See `resource_type_code`) unless
    #   it is specified. If this parameter is used a `resource_type_code`
    #   must also be specified.
    #
    # @argument originality_report[workflow_state] [String]
    #   May be set to "pending", "error", or "scored". If an originality score
    #   is provided a workflow state of "scored" will be inferred.
    #
    # @argument originality_report[error_message] [String]
    #   A message describing the error. If set, the "workflow_state"
    #   will be set to "error."
    #
    # @returns OriginalityReport
    def update
      updates = { error_message: nil }.merge(update_report_params)
      if @report.update(updates)
        @report.copy_to_group_submissions_later!
        render json: api_json(@report, @current_user, session)
      else
        render json: @report.errors, status: :bad_request
      end
    end

    # @API Show an Originality Report
    # Get a single originality report
    #
    # @returns OriginalityReport
    def show
      render json: api_json(@report, @current_user, session)
    end

    def lti2_service_name
      ORIGINALITY_REPORT_SERVICE
    end

    private

    def ensure_tool_proxy_associated
      render_unauthorized_action unless tool_proxy_associated?
    end

    def link_fragment
      Lti::Asset.global_context_id_for(submission)
    end

    def tool_proxy_associated?
      PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)
    end

    def create_attributes
      (update_attributes + [:file_id]).freeze # rubocop:disable Rails/ActiveRecordAliases not ActiveRecord::Base#update_attributes
    end

    def update_attributes
      %i[
        error_message
        originality_report_file_id
        originality_report_url
        originality_score
        workflow_state
      ].freeze
    end

    def lti_link_attributes
      [tool_setting: %i[resource_url resource_type_code]].freeze
    end

    def assignment
      @_assignment ||= api_find(Assignment, params[:assignment_id])
    end

    def submission
      @_submission ||= if params[:file_id].present?
                         AttachmentAssociation.find_by(attachment_id: params[:file_id])&.context
                       else
                         Submission.active.find(params[:submission_id])
                       end
    end

    def attachment
      @_attachment ||= begin
        attachment = Attachment.find(params[:file_id]) if params[:file_id].present?
        if attachment.blank? && params.require(:originality_report)[:file_id].present?
          attachment = Attachment.find(params.require(:originality_report)[:file_id])
        end
        attachment
      end
    end

    def attachment_association
      @_attachment_association ||= begin
        file = originality_report&.attachment || attachment
        file.attachment_associations.find { |a| a.context == submission }
      end
    end

    def create_report_params
      @_create_report_params ||= begin
        report_attributes = params.require(:originality_report).permit(create_attributes).to_unsafe_h.merge(
          submission_id: params.require(:submission_id),
          submission_time: @version&.submitted_at
        )
        report_attributes[:lti_link_attributes] = lti_link_params
        report_attributes
      end
    end

    def update_report_params
      @_update_report_params ||= begin
        report_attributes = params.require(:originality_report).permit(update_attributes) # rubocop:disable Rails/ActiveRecordAliases not ActiveRecord::Base#update_attributes
        report_attributes[:lti_link_attributes] = lti_link_params
        report_attributes
      end
    end

    def lti_link_params
      @_lti_link_params ||= if lti_link_settings&.dig("tool_setting", "resource_type_code")
                              lti_link_settings["tool_setting"].merge({
                                                                        id: @report&.lti_link&.id,
                                                                        product_code: tool_proxy.product_family.product_code,
                                                                        vendor_code: tool_proxy.product_family.vendor_code
                                                                      })
                            else
                              {
                                id: @report&.lti_link&.id,
                                _destroy: true
                              }
                            end
    end

    def lti_link_settings
      @_lti_link_settings ||= begin
        link_attributes = params.require(:originality_report).permit(lti_link_attributes).to_unsafe_h
        link_attributes = current_lti_link if link_attributes.blank?
        link_attributes
      end
    end

    def current_lti_link
      @report&.lti_link&.as_json(only: [:resource_url, :resource_type_code])&.tap { |v| v["tool_setting"] = v.delete "link" }
    end

    def attachment_required?
      !submission.assignment.submission_types.include?("online_text_entry")
    end

    def attachment_in_context
      verify_submission_attachment(attachment, submission)
    end

    def report_by_attempt(attempt)
      # Assign @version so if create a new originality report, we can match up
      # the submission time with the version.  This is important because they
      # could be creating a report for the version that is not the latest.
      @version = submission.versions.map(&:model).find { |m| m.attempt.to_s == attempt.to_s }
      raise ActiveRecord::RecordNotFound unless @version

      submission.originality_reports.find_by(submission_time: @version.submitted_at)
    end

    def find_originality_report
      raise ActiveRecord::RecordNotFound if submission.blank?

      @report = OriginalityReport.find_by(id: params[:id])
      # NOTE: we could end up looking up by file_id, attachment: nil or attempt
      # even in the `update` or `show` endpoints, if they give us a bogus report id :/
      @report ||= report_by_attachment(attachment)
      return if params[:originality_report].blank? || attachment.present?

      unless attachment_required?
        # For Text Entry cases (there is never an attachment), in the `create`
        # method, clients can choose which submission version the report is for
        # by supplying the attempt number.  Thus we can tell if they are
        # updating an exising report or making a new one for a new version.
        @report ||=
          if params.require(:originality_report)[:attempt].present?
            report_by_attempt(params[:originality_report][:attempt])
          else
            submission.originality_reports.find_by(attachment: nil)
          end
      end
    end

    def report_by_attachment(attachment)
      return if attachment.blank?

      if submission.present?
        OriginalityReport.find_by(attachment_id: attachment&.id, submission:)
      else
        OriginalityReport.find_by(attachment_id: attachment&.id)
      end
    end

    def report_in_context
      raise ActiveRecord::RecordNotFound if @report.blank?

      verify_submission_attachment(@report.attachment, submission)
    end

    def attachment_in_history?(attachment, submission)
      submission.submission_history.any? do |s|
        s.attachment_ids.include?(attachment.id.to_s) ||
          s.attachment_ids.include?(attachment.global_id.to_s)
      end
    end

    def verify_submission_attachment(attachment, submission)
      raise ActiveRecord::RecordNotFound if submission.blank? || (attachment_required? && attachment.blank?)

      if submission.assignment != assignment || (attachment_required? && !attachment_in_history?(attachment, submission))
        render_unauthorized_action
      end
    end

    # @!appendix Originality Report UI Locations
    #
    # {include:file:doc/api/originality_report_appendix.md}
  end
end
