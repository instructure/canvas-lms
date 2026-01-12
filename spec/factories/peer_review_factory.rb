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
    # Calculate dates based on parent assignment to respect validation rules
    parent_due = @parent_assignment&.due_at
    parent_unlock = @parent_assignment&.unlock_at
    parent_lock = @parent_assignment&.lock_at

    # Peer review unlock must be >= parent due_at
    unlock_at = if parent_due
                  parent_due + 1.day
                else
                  1.day.from_now
                end

    # If parent has unlock_at, peer review unlock must also be >= that
    unlock_at = [unlock_at, parent_unlock].compact.max if parent_unlock

    # Peer review due must be >= parent due_at
    due_at = if parent_due
               parent_due + 1.week
             else
               1.week.from_now
             end

    # Peer review lock must be <= parent lock_at if it exists
    lock_at = if parent_lock
                [parent_lock, due_at + 1.week].min
              else
                2.weeks.from_now
              end

    {
      points_possible: 10,
      grading_type: "points",
      due_at:,
      unlock_at:,
      lock_at:
    }
  end
end
