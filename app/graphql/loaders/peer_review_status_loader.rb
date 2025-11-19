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

module Loaders
  class PeerReviewStatusLoader < GraphQL::Batch::Loader
    def initialize(assignment_id)
      super()
      @assignment_id = assignment_id
    end

    def perform(user_ids)
      must_review_counts = AllocationRule.active
                                         .where(assignment_id: @assignment_id, assessor_id: user_ids, must_review: true)
                                         .group(:assessor_id)
                                         .count

      completed_reviews_counts = AssessmentRequest.joins(:submission)
                                                  .where(
                                                    assessor_id: user_ids,
                                                    workflow_state: "completed",
                                                    submissions: { assignment_id: @assignment_id }
                                                  )
                                                  .group(:assessor_id)
                                                  .count

      user_ids.each do |user_id|
        status = {
          must_review_count: must_review_counts[user_id] || 0,
          completed_reviews_count: completed_reviews_counts[user_id] || 0
        }
        fulfill(user_id, status)
      end
    end
  end
end
