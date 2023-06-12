# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module DataFixup::AddPostPoliciesToAssignments
  def self.set_submission_posted_at_dates(start_at, end_at)
    # For all submissions:
    # - Set the posted_at time of the assignment's submissions to nil (if the
    #   assignment is muted) or to the submission's graded_at time
    Submission.joins(:assignment).where(id: start_at..end_at)
              .where.not(PostPolicy.where("assignment_id = assignments.id").arel.exists)
              .find_ids_in_batches do |submission_ids|
      Submission.joins(:assignment)
                .where(id: submission_ids)
                .where(<<~SQL.squish)
                  CASE assignments.muted
                    WHEN TRUE
                      THEN posted_at IS NOT NULL
                    ELSE
                      graded_at IS NOT NULL AND posted_at IS NULL OR graded_at IS NULL AND posted_at IS NOT NULL OR posted_at<>graded_at
                  END
                SQL
                .update_all("posted_at = (CASE assignments.muted WHEN TRUE THEN NULL ELSE graded_at END), updated_at = NOW()")
    end
  end

  def self.create_post_policies(start_at, end_at)
    created_at = Time.zone.now

    Assignment.where.not(PostPolicy.where("assignment_id = assignments.id").arel.exists)
              .where(context_id: start_at..end_at)
              .find_in_batches do |assignments|
      assignment_post_policy_records = assignments.map do |assignment|
        post_manually = assignment.muted? || assignment.anonymous_grading? || assignment.moderated_grading?

        {
          assignment_id: assignment.id,
          created_at:,
          course_id: assignment.context_id,
          post_manually:,
          updated_at: created_at
        }
      end
      PostPolicy.bulk_insert(assignment_post_policy_records)
    end

    Course.where(id: start_at..end_at)
          .where.not(PostPolicy.where("course_id = courses.id AND assignment_id IS NULL").arel.exists)
          .find_ids_in_batches do |course_ids|
      course_post_policy_records = course_ids.map do |id|
        {
          assignment_id: nil,
          course_id: id,
          created_at:,
          post_manually: false,
          updated_at: created_at
        }
      end
      PostPolicy.bulk_insert(course_post_policy_records)
    end
  end
end
