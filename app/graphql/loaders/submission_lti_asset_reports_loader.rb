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
# active processors.
class Loaders::SubmissionLtiAssetReportsLoader < GraphQL::Batch::Loader
  def perform(submission_ids)
    results =
      Lti::AssetReport
      .active
      .for_active_processors
      .for_submissions(submission_ids)
      .preload(:asset)
      .group_by { |rep| rep.asset.submission_id }

    submission_ids.each do |sub_id|
      fulfill(sub_id, results[sub_id] || [])
    end
  end
end
