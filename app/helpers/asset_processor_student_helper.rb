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
#
module AssetProcessorStudentHelper
  def raw_asset_reports(submission:)
    return nil if submission.blank?
    return nil unless submission.root_account&.feature_enabled?(:lti_asset_processor)

    active_ap_ids = submission.assignment.lti_asset_processors.pluck(:id)
    return nil if active_ap_ids.empty?

    sql = [
      "#{Lti::Asset.table_name}.submission_id = :submission_id AND
       ((#{Lti::Asset.table_name}.attachment_id IN (:attachment_ids)) OR
       (#{Lti::Asset.table_name}.submission_attempt = :submission_attempt))",
      {
        submission_id: submission.id,
        attachment_ids: submission.attachment_associations.pluck(:attachment_id),
        submission_attempt: submission.attempt
      }
    ]

    # Retrieve all reports regardless of processing progress
    visible_reports = Lti::AssetReport
                      .joins(:asset)
                      .preload(asset: :attachment)
                      .joins(:asset_processor)
                      .where(sql)
                      .where(lti_asset_processor_id: active_ap_ids)
                      .where(visible_to_owner: true)
                      .active
                      .to_a

    processed_visible_reports = visible_reports.select { |r| r.processing_progress == Lti::AssetReport::PROGRESS_PROCESSED }

    if processed_visible_reports.any?
      processed_visible_reports
    elsif visible_reports.any?
      # Show "No results" on the UI
      []
    else
      # Hide the whole Document Processors column on the UI
      nil
    end
  end

  def asset_reports(submission:)
    raw_reports = raw_asset_reports(submission:)

    raw_reports&.map do |report|
      report.info_for_display.merge(
        {
          asset_processor_id: report.lti_asset_processor_id,
          asset: {
            id: report.asset.id,
            attachment_id: report.asset.attachment_id,
            attachment_name: report.asset.attachment&.name,
            submission_id: report.asset.submission_id,
            submission_attempt: report.asset.submission_attempt
          }
        }
      )
    end
  end

  def asset_processors(assignment:)
    return nil unless assignment.root_account.feature_enabled?(:lti_asset_processor)

    assignment.lti_asset_processors.info_for_display
  end
end
