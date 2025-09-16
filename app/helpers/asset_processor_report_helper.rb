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
module AssetProcessorReportHelper
  # Returns a hash of submission_id => [Lti::AssetReport1, Lti::AssetReport2] | [] | nil
  def raw_asset_reports(submission_ids:, for_student:)
    mate_submissions_by_primary = mate_submissions(submission_ids)
    all_submission_ids = [submission_ids, mate_submissions_by_primary.values].flatten.uniq

    # Retrieve all reports regardless of processing progress
    visible_reports = Lti::AssetReport
                      .active
                      .for_active_processors
                      .for_submissions(all_submission_ids)
                      .preload(:asset)
                      .preload(asset: :attachment)

    if for_student
      visible_reports = visible_reports.preload(asset: :submission)
                                       .preload(asset: { submission: :attachment_associations })
      # Students can only see reports that are marked visible_to_owner
      visible_reports = visible_reports.where(visible_to_owner: true)
      # And reports of the last submission attempt
      visible_reports = visible_reports.filter do |report|
        submission = report.asset.submission
        next false if submission.blank?

        attachment_ids = submission.attachment_ids&.presence&.split(",") || []
        attachment_ids.include?(report.asset.attachment_id.to_s) || report.asset.submission_attempt == submission.attempt
      end
    end

    reports_by_submission = visible_reports.group_by { |rep| rep.asset.submission_id }

    ret = {}
    submission_ids.each do |sub_id|
      sub_ids = [sub_id] + (mate_submissions_by_primary[sub_id] || [])
      reports = sub_ids.uniq.flat_map { reports_by_submission[it] || [] }
      ret[sub_id] = if for_student
                      processed_visible_reports = reports.select { |r| r.processing_progress == Lti::AssetReport::PROGRESS_PROCESSED }
                      if processed_visible_reports.any?
                        processed_visible_reports
                      elsif reports.any?
                        # There are visible reports, but not processed yet -> Show "No results" on the UI
                        []
                      else
                        # No reports or not visible for students -> Hide the whole Document Processors column on the UI
                        nil
                      end
                    else
                      reports
                    end
    end
    ret
  end

  # Generally, we should prefer using graphql query instead of REST endpoints that use this helper function
  def asset_reports_info_for_display(submission:, for_student: true)
    return nil if submission.blank?
    return nil unless submission.root_account&.feature_enabled?(:lti_asset_processor)

    raw_reports = raw_asset_reports(submission_ids: [submission.id], for_student:)[submission.id]

    raw_reports&.map do |report|
      report.info_for_display.merge(
        {
          # TODO: post refactor (INTEROP-9588), this should be the only usage
          # of info_for_display, so we can safely move the _id conversion there
          _id: report.id.to_s,
          processorId: report.lti_asset_processor_id&.to_s,
          asset: {
            attachmentId: report.asset.attachment_id&.to_s,
            attachmentName: report.asset.attachment&.name,
            submissionAttempt: report.asset.submission_attempt
          }
        }
      )
    end
  end

  # TODO: remove after refactor (INTEROP-9588)
  def asset_reports_legacy_format(submission:, for_student: true)
    return nil if submission.blank?
    return nil unless submission.root_account&.feature_enabled?(:lti_asset_processor)

    raw_reports = raw_asset_reports(submission_ids: [submission.id], for_student:)[submission.id]

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

  private

  def mate_submissions(submission_ids)
    submissions_with_groups = Submission.where(id: submission_ids)
                                        .where.not(group_id: nil)
                                        .pluck(:id, :group_id, :assignment_id)
    groupmate_submissions(submissions_with_groups)
  end

  # Returns a hash from submission_id -> [array of submission ids of all submissions in the same group]
  # Example: {1157 => [1157, 1159]} 1157, 1159 submissions are in the same group
  def groupmate_submissions(submissions_with_groups)
    mate_submissions_by_primary = {}
    return mate_submissions_by_primary if submissions_with_groups.blank?

    assignment_group_pairs = submissions_with_groups.map { |_id, group_id, assignment_id| [assignment_id, group_id] }.uniq

    mate_submissions_in_groups = []
    unless assignment_group_pairs.empty?
      grouped = assignment_group_pairs.group_by { |a_id, _g_id| a_id }
      # This connection could end up having many groups and submissions
      # therefore do this select in batches
      grouped.each_slice(100) do |chunk|
        relations = chunk.map do |a_id, pairs|
          Submission.where(assignment_id: a_id, group_id: pairs.map { |_, g_id| g_id })
        end
        combined = relations.reduce { |acc, rel| acc.or(rel) } || Submission.none
        mate_submissions_in_groups.concat(
          combined.pluck(:id, :group_id, :assignment_id)
        )
      end
    end
    mate_submissions_by_assignment_group = mate_submissions_in_groups.group_by { |_id, group_id, assignment_id| [assignment_id, group_id] }

    submissions_with_groups.each do |s_id, g_id, a_id|
      mates = mate_submissions_by_assignment_group[[a_id, g_id]] || []
      mate_submissions_by_primary[s_id] = mates.map(&:first)
    end

    mate_submissions_by_primary
  end
end
