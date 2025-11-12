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
  include AssetProcessorReportHelper

  def initialize(for_student:, latest:)
    super()
    raise ArgumentError if for_student && !latest

    @for_student = for_student
    @last_submission_attempt_only = latest
  end

  def perform(submission_ids)
    reports_by_submission = raw_asset_reports(
      submission_ids:,
      for_student: @for_student,
      last_submission_attempt_only: @last_submission_attempt_only
    )

    submission_ids.each do |sub_id|
      fulfill(sub_id, reports_by_submission[sub_id])
    end
  end
end
