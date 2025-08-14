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

# Loads LTI Asset Reports for student access using AssetProcessorStudentHelper
# This loader is specifically designed for student-facing GraphQL queries
# and uses the helper's raw_asset_reports method for proper filtering
class Loaders::SubmissionLtiAssetReportsStudentLoader < GraphQL::Batch::Loader
  include AssetProcessorStudentHelper

  def perform(submission_ids)
    submission_ids.each do |submission_id|
      submission = Submission.find_by(id: submission_id)
      next fulfill(submission_id, nil) unless submission

      reports = raw_asset_reports(submission:)
      fulfill(submission_id, reports)
    end
  end
end
