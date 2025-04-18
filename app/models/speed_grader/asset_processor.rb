# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module SpeedGrader
  # Probably temp class, mock AP data
  module AssetProcessor
    module_function

    # should use Lti::AssetProcessor.processors_info_for_display()
    # tool id & name always given so we have a default icon if tool icon url fails
    # This should be the same as the existing APs
    MOCK_LTI_ASSET_PROCESSORS_DATA = [
      {
        "id" => 12,
        "title" => "Ap1 title",
        "text" => "Ap1 text",
        "tool_id" => 123,
        "tool_name" => "Tool 123 name",
        "tool_placement_label" => "tool 123 placement label",
        "icon_or_tool_icon_url" => "https://static.thenounproject.com/png/2130-200.png",
      },
      {
        "id" => 34,
        "title" => "Ap2 title",
        "text" => "Ap2 text",
        "tool_id" => 123,
        "tool_name" => "Tool 123 name",
        "tool_placement_label" => "tool 123 placement label",
        "icon_or_tool_icon_url" => "https://static.thenounproject.com/png/2131-200.png",
      },
      {
        "id" => 56,
        "title" => "Ap3 title",
        "text" => "Ap3 text",
        "tool_id" => 345,
        "tool_name" => "Tool 345 name",
      },
    ].freeze

    MOCK_LTI_ASSET_REPORTS = [
      {
        id: 1001,
        resubmit_url_path: "/asset_processors/12/asset/567/resubmit",

        report_type: "originality",
        title: "Eye AP1 Originality",
        comment: "Processing failed due to an error",
        processing_progress: "Failed",
        error_code: "UNSUPPORTED_ASSET_TYPE",
        priority: 3,
      },
      {
        id: 1002,
        launch_url_path: "/asset_processors/12/reports/1002/launch",
        report_type: "coolness",
        title: "Eye AP1 Coolness",
        comment: "This submission is very cool 😎",
        score_given: 94,
        score_maximum: 100,
        indication_color: "#0000EC",
        indication_alt: "High coolness content",
        processing_progress: "Processed",
        priority: 1,
      },
      {
        id: 1003,
        resubmit_url_path: "/asset_processors/34/asset/789/resubmit",
        report_type: "originality",
        title: "Eye AP2 Originality",
        comment: "please hold... ⏳",
        processing_progress: "Processing",
        priority: 5,
      },
      {
        id: 1004,
        launch_url_path: "/asset_processors/12/reports/1004/launch",
        report_type: "originality",
        score_given: 50,
        score_maximum: 100,
        indication_color: "#ECEC00",
        indication_alt: "OriginalTool 50% indication_alt",
        processing_progress: "Processed",
        priority: 3,
      }
    ].freeze

    # For each attachment: an object from processor id -> array of reports
    MOCK_LTI_ASSET_REPORTS_LISTS = [
      {
        "12" => MOCK_LTI_ASSET_REPORTS[0..1],
        "34" => MOCK_LTI_ASSET_REPORTS[2..2],
      },

      {
        "56" => MOCK_LTI_ASSET_REPORTS[3..],
      }
    ].freeze

    def merge_mock_lti_asset_processor_data!(assignment:, response_hash:)
      return unless Rails.env.development?
      return unless ENV["LTI_ASSET_PROCESSOR_MOCK_SPEED_GRADER"]
      return unless assignment.root_account.feature_enabled?(:lti_asset_processor)

      response_hash[:lti_asset_processors] = MOCK_LTI_ASSET_PROCESSORS_DATA
    end

    def merge_mock_lti_asset_reports_data!(assignment:, submission_hash:)
      return unless Rails.env.development?
      return unless ENV["LTI_ASSET_PROCESSOR_MOCK_SPEED_GRADER"]
      return unless assignment.root_account.feature_enabled?(:lti_asset_processor)

      # submission['attachments'] only seems to include the last submission version's attachments
      attachment_ids = submission_hash["submission_history"].map do |sub|
        sub.versioned_attachments&.map do |attachment|
          attachment["id"]
        end
      end.flatten.compact

      return if attachment_ids.blank?

      reports_by_attachment = {}
      attachment_ids.each_with_index do |attach_id, index|
        # loop through all sets of of mock reports, ignore assignment/submission/attachment
        reports_by_attachment[attach_id] =
          MOCK_LTI_ASSET_REPORTS_LISTS[index % MOCK_LTI_ASSET_REPORTS_LISTS.length]
      end
      submission_hash[:lti_asset_reports] = { by_attachment: reports_by_attachment }
    end
  end
end
