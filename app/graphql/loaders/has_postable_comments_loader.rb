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
#
class Loaders::HasPostableCommentsLoader < GraphQL::Batch::Loader
  def perform(submission_ids)
    has_postable_comments = SubmissionComment
                            .where(submission: submission_ids)
                            .group(:submission_id)
                            # This calculation replicates the logic in Submission#postable_comments?
                            .pluck(:submission_id, Arel.sql("BOOL_OR(hidden AND NOT draft)")).to_h

    submission_ids.each do |submission_id|
      fulfill(submission_id, has_postable_comments.fetch(submission_id, false))
    end
  end
end
