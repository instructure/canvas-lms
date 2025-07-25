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

# Loads all the LTI Asset Reports for a given submission(s),
# in one query, including the assets, only for reports for
# active processors. For group assignments, also includes reports
# from other submissions in the same group.
class Loaders::SubmissionLtiAssetReportsLoader < GraphQL::Batch::Loader
  def perform(submission_ids)
    # First, find all submissions that are in the same groups as our requested submissions
    submissions_with_groups = Submission.where(id: submission_ids)
                                        .where.not(group_id: nil)
                                        .pluck(:id, :group_id, :assignment_id)

    all_submission_ids = submission_ids.dup

    if submissions_with_groups.present?
      mate_submissions_by_primary = groupmate_submissions(submissions_with_groups)
      all_submission_ids.concat(mate_submissions_by_primary.values.flatten)
      all_submission_ids.uniq!
    end

    all_reports =
      Lti::AssetReport
      .active
      .for_active_processors
      .for_submissions(all_submission_ids)
      .preload(:asset)

    reports_by_submission = all_reports.group_by { |rep| rep.asset.submission_id }

    submission_ids.each do |sub_id|
      sub_ids = [sub_id]
      if submissions_with_groups.present?
        sub_ids += mate_submissions_by_primary[sub_id] || []
      end
      fulfill(sub_id, sub_ids.uniq.flat_map { |id| reports_by_submission[id] || [] })
    end
  end

  def groupmate_submissions(submissions_with_groups)
    mate_submissions_by_primary = {}
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
