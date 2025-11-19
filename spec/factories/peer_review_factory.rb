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

module Factories
  def peer_review_model(opts = {})
    @parent_assignment = opts.delete(:parent_assignment)
    course = if @parent_assignment
               opts.delete(:course)
               @parent_assignment.course
             else
               opts.delete(:course) || opts[:context] || course_model(reusable: true)
             end

    @parent_assignment ||= assignment_model(
      course:,
      title: "Parent Assignment",
      points_possible: 20,
      peer_reviews: true,
      submission_types: "online_text_entry"
    )

    @parent_assignment.peer_reviews = true unless @parent_assignment.peer_reviews?
    @parent_assignment.save!

    course.enable_feature!(:peer_review_allocation_and_grading)

    @peer_review_sub_assignment = PeerReview::PeerReviewCreatorService.call(
      parent_assignment: @parent_assignment,
      **valid_attributes.merge(opts)
    )
    @peer_review_sub_assignment
  end

  def valid_attributes
    {
      points_possible: 10,
      grading_type: "points",
      due_at: 1.week.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 2.weeks.from_now
    }
  end
end
