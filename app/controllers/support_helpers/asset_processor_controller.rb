# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module SupportHelpers
  class AssetProcessorController < ApplicationController
    include SupportHelpers::ControllerHelpers

    before_action :require_site_admin

    protect_from_forgery with: :exception

    ASSIGNMENT_ATTRS = %w[id name created_at updated_at].freeze
    SUBMISSION_ATTRS = %w[id attempt workflow_state submitted_at created_at updated_at].freeze
    PROCESSOR_ATTRS = %w[id title url context_external_tool_id workflow_state created_at updated_at].freeze
    TOOL_ATTRS = %w[id name description url domain workflow_state lti_version created_at updated_at].freeze
    HANDLER_ATTRS = %w[id context_external_tool_id notice_type url max_batch_size workflow_state created_at updated_at].freeze
    ASSET_ATTRS = %w[id attachment_id submission_attempt uuid created_at updated_at].freeze
    REPORT_ATTRS = %w[
      id
      lti_asset_id
      lti_asset_processor_id
      processing_progress
      report_type
      title
      result
      comment
      indication_color
      indication_alt
      error_code
      priority
      created_at
      updated_at
      extensions
      timestamp
      workflow_state
      visible_to_owner
    ].freeze

    COLOR_ASSIGNMENT = "#D5F5E3" # Light green
    COLOR_SUBMISSION = "#D6EAF8" # Light blue
    COLOR_TOOL = "#FCF3CF" # Yellow
    COLOR_HANDLER = "#F5CBA7" # Orange
    COLOR_PROCESSOR = "#E59866" # Orange-brown
    COLOR_ASSET = "#D2B4DE" # Light lavender
    COLOR_REPORT = "#F9E79F" # Light yellow
    COLOR_INACTIVE = "#CCCCCC" # Gray

    # @API Get Asset Processor Details
    # @internal
    # Get all asset processor information for a specific submission including
    # Asset Processors, Assets, and Asset Reports. This endpoint is intended
    # for troubleshooting and support purposes.
    #
    # Example Request:
    # http://canvas-web.inseng.test/api/v1/support_helpers/asset_processor/submission_details?
    #   assignment_id=123&student_id=456
    #
    # Example Graph Request:
    # http://canvas-web.inseng.test/api/v1/support_helpers/asset_processor/submission_details?
    #   assignment_id=123&student_id=456&graph=true
    #
    # @argument assignment_id [Required, Integer]
    #   The ID of the assignment containing the submission to retrieve asset processor details for
    # @argument student_id [Required, Integer]
    #   The ID of the student (user) who owns the submission
    # @argument graph [Optional, Boolean]
    #   If set to true, it returns a DOT graph representation of the asset processor relationships
    def submission_details
      assignment_id = params.require(:assignment_id)
      student_id = params.require(:student_id)
      graph_format = params[:graph] == "true"

      assignment = api_find(Assignment, assignment_id)
      submission = assignment.submissions.where(user_id: student_id).first

      if submission.nil?
        render json: { error: "Submission not found" }, status: :not_found
        return
      end

      asset_processors = Lti::AssetProcessor.where(assignment_id: assignment.id)
                                            .preload(context_external_tool: :lti_notice_handlers)
                                            .order(id: :desc)

      assets = Lti::Asset.where(submission_id: submission.id)
                         .preload(:asset_reports, :attachment)
                         .order(id: :desc)

      asset_ids = assets.pluck(:id)
      asset_reports = if asset_ids.present?
                        Lti::AssetReport.where(lti_asset_id: asset_ids)
                                        .preload(:asset_processor)
                                        .order(id: :desc)
                      else
                        []
                      end

      context_external_tools = asset_processors.map(&:context_external_tool).uniq.compact
      notice_handlers = context_external_tools.flat_map(&:lti_notice_handlers).sort_by(&:id).reverse

      if graph_format
        render plain: generate_graphviz_dot(
          assignment:,
          submission:,
          asset_processors:,
          context_external_tools:,
          notice_handlers:,
          assets:,
          asset_reports:
        )
      else
        render json: {
          assignment: assignment.attributes.slice(*ASSIGNMENT_ATTRS),
          submission: submission.attributes.slice(*SUBMISSION_ATTRS),
          asset_processors: asset_processors.map { |p| p.attributes.slice(*PROCESSOR_ATTRS) },
          context_external_tools: context_external_tools.map { |t| t.attributes.slice(*TOOL_ATTRS) },
          notice_handlers: notice_handlers.map { |h| h.attributes.slice(*HANDLER_ATTRS) },
          assets: assets.map do |asset|
            asset.attributes.slice(*ASSET_ATTRS).merge(attachment_name: asset.attachment&.display_name)
          end,
          asset_reports: asset_reports.map { |r| r.attributes.slice(*REPORT_ATTRS) }
        }
      end
    end

    # @API Trigger Asset Processor Notice Resubmission
    # @internal
    # Go through all the submissions in the context (assignment or course)
    # and trigger asset processor notices for each submission.
    # One of assignment_id or course_id is required, and the optional tool_id
    # can be used to send notices only to a specific tool's Asset Processors.
    #
    # Example Request:
    # curl -X POST 'http://canvas-web.inseng.test/api/v1/support_helpers/asset_processor/bulk_resubmit' \
    # -H "Authorization: Bearer $Canvas-User-Token" \
    # -H "Content-Type: application/json" \
    # -d '{"assignment_id":123}'
    #
    # @argument assignment_id [Optional, Integer]
    #   The ID of the assignment we want to resubmit notices for
    # @argument course_id [Optional, Integer]
    #   The ID of the course containing assignments we want to resubmit notices for
    # @argument tool_id [Optional, Integer]
    #   The ID of the external tool to filter asset processors we want to resend notices
    def bulk_resubmit
      permitted = params.permit(:assignment_id, :course_id, :tool_id)
      assignment_id = permitted[:assignment_id].presence
      course_id = permitted[:course_id].presence
      tool_id = permitted[:tool_id].presence

      if assignment_id
        context = Assignment.find(assignment_id)
        return render json: { error: "Invalid assignment, for discussions use bulk_resubmit for discussions" }, status: :bad_request if context.discussion_topic?
      elsif course_id
        context = Course.find(course_id)
      else
        render json: { error: "assignment_id or course_id is required" }, status: :bad_request
        return
      end

      run_fixer(
        SupportHelpers::AssetProcessorNoticeResubmission,
        context,
        tool_id
      )
    end

    # @API Trigger Discussion Asset Processor Notice Resubmission
    # @internal
    # Go through all the discussion entries in the context
    # (discussion topic or course) and trigger asset processor
    # notices for each discussion entry version.
    # One of discussion_topic_id or course_id is required, and
    # the optional tool_id can be used to send notices only to a
    # specific tool's Asset Processors.
    #
    # Example Request:
    # curl -X POST 'http://canvas-web.inseng.test/api/v1/support_helpers/asset_processor_discussion/bulk_resubmit' \
    # -H "Authorization: Bearer $Canvas-User-Token" \
    # -H "Content-Type: application/json" \
    # -d '{"discussion_topic_id":123}'
    #
    # @argument discussion_topic_id [Optional, Integer]
    #   The ID of the discussion topic we want to resubmit notices for
    # @argument course_id [Optional, Integer]
    #   The ID of the course containing discussion topics we want to resubmit notices for
    # @argument tool_id [Optional, Integer]
    #   The ID of the external tool to filter asset processors we want to resend notices
    def bulk_resubmit_discussion
      permitted = params.permit(:discussion_topic_id, :course_id, :tool_id)
      discussion_topic_id = permitted[:discussion_topic_id].presence
      course_id = permitted[:course_id].presence
      tool_id = permitted[:tool_id].presence

      if discussion_topic_id
        context = DiscussionTopic.find(discussion_topic_id)
        return render json: { error: "Invalid discussion" }, status: :bad_request unless context.graded?
      elsif course_id
        context = Course.find(course_id)
      else
        render json: { error: "discussion_topic_id or course_id is required" }, status: :bad_request
        return
      end

      run_fixer(
        SupportHelpers::AssetProcessorDiscussionNoticeResubmission,
        context,
        tool_id
      )
    end

    private

    def generate_graphviz_dot(assignment:, submission:, asset_processors:, context_external_tools:, notice_handlers:, assets:, asset_reports:)
      @dot = []
      @dot << "digraph AssetProcessorGraph {"
      @dot << "  // Graph styling"
      @dot << "  graph [rankdir=LR, fontsize=12, pad=0.5];"
      @dot << '  node [shape=box, style="filled,rounded"];'
      @dot << ""

      # Node definitions
      draw_node("Assignment", assignment, COLOR_ASSIGNMENT, { Name: assignment.name, ID: assignment.id })
      draw_node("Submission", submission, COLOR_SUBMISSION, { ID: submission.id, Attempt: submission.attempt })
      context_external_tools.each { |tool| draw_node("Tool", tool, COLOR_TOOL, { ID: tool.id }) }
      notice_handlers.each { |handler| draw_node("Notice Handler", handler, COLOR_HANDLER, { ID: handler.id, Type: handler.notice_type }) }
      asset_processors.each { |processor| draw_node("Asset Processor", processor, COLOR_PROCESSOR, { ID: processor.id }) }
      assets.each { |asset| draw_asset_node(asset) }
      asset_reports.each { |report| draw_asset_report_node(report) }
      @dot << ""

      # Relationships
      @dot << "  // Relationships"
      @dot << "  Assignment_#{assignment.id} -> Submission_#{submission.id};"
      asset_processors.each { |p| @dot << "  Tool_#{p.context_external_tool_id} -> AssetProcessor_#{p.id};" }
      notice_handlers.each { |h| @dot << "  Tool_#{h.context_external_tool_id} -> NoticeHandler_#{h.id};" }
      assets.each { |asset| @dot << "  Submission_#{submission.id} -> Asset_#{asset.id};" }
      asset_reports.each do |report|
        @dot << "  Asset_#{report.lti_asset_id} -> AssetReport_#{report.id};"
        @dot << "  AssetProcessor_#{report.lti_asset_processor_id} -> AssetReport_#{report.id};"
      end

      @dot << "}"
      @dot.join("\n")
    end

    def format_time(modified_time, created_time = nil)
      time = modified_time.presence || created_time
      time&.strftime("%Y-%m-%d %H:%M") || "N/A"
    end

    def draw_node(name, model, color, attrs)
      label_lines = [name]
      attrs.each { |k, v| label_lines << "#{k}: #{v}" }
      label_lines << "Modified: #{format_time(model.updated_at, model.created_at)}"

      fill_color = color
      if model.respond_to?(:workflow_state)
        fill_color = COLOR_INACTIVE if model.workflow_state == "deleted"
      end

      @dot << "  #{name.delete(" ")}_#{model.id} [fillcolor=\"#{fill_color}\" label=\"#{label_lines.join('\n')}\"];"
    end

    def draw_asset_node(asset)
      attrs = { ID: asset.id, Attempt: asset.submission_attempt, "Attachment ID": asset.attachment_id }
      attrs["Attachment"] = asset.attachment.display_name if asset.attachment&.display_name.present?
      draw_node("Asset", asset, COLOR_ASSET, attrs)
    end

    def draw_asset_report_node(report)
      attrs = {
        ID: report.id, Progress: report.processing_progress, Type: report.report_type, Priority: report.priority
      }
      draw_node("Asset Report", report, COLOR_REPORT, attrs)
    end
  end
end
