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
  def self.run(start_at, end_at)
    # find_ids_in_ranges (which is used to call this function in the migration)
    # defaults to a batch size of 1000, so we can fetch all of these in one go
    courses_to_update = Course.where(id: start_at..end_at).
      where("NOT EXISTS (?)", PostPolicy.where("course_id = courses.id AND assignment_id IS NULL")).
      to_a

    create_assignment_post_policies(courses: courses_to_update)
    create_course_post_policies(courses: courses_to_update)
  end

  def self.create_assignment_post_policies(courses:)
    # If an assignment already has a PostPolicy object, likely from a previous
    # run of this data-fixup, we can assume it's in good order and skip it.
    #
    # For other assignments:
    # - Set the posted_at time of the assignment's submissions to nil (if the
    #   assignment is muted) or to the submission's graded_at time
    # - Create a post policy for the assignment:
    #   - Muted assignments are considered manually posted
    #   - Anonymous/moderated assignments are also manually posted
    #   - All other assignments are automatically posted
    Assignment.where(course: courses).
      where("NOT EXISTS (?)", PostPolicy.where("assignment_id = #{Assignment.quoted_table_name}.id")).
      find_in_batches do |assignment_batch|

      ActiveRecord::Base.connection.exec_update <<~SQL
        UPDATE #{Submission.quoted_table_name}
        SET
          posted_at = (CASE #{Assignment.quoted_table_name}.muted WHEN TRUE THEN NULL ELSE graded_at END),
          updated_at = NOW()
        FROM #{Assignment.quoted_table_name}
        WHERE
          #{Submission.quoted_table_name}.assignment_id = #{Assignment.quoted_table_name}.id AND
          #{Submission.quoted_table_name}.assignment_id IN (#{assignment_batch.pluck(:id).join(', ')})
      SQL

      created_at = Time.zone.now
      assignment_post_policy_records = assignment_batch.map do |assignment|
        post_manually = assignment.muted? || assignment.anonymous_grading? || assignment.moderated_grading?

        {
          assignment_id: assignment.id,
          created_at: created_at,
          course_id: assignment.context_id,
          post_manually: post_manually,
          updated_at: created_at
        }
      end
      PostPolicy.bulk_insert(assignment_post_policy_records)
    end
  end

  def self.create_course_post_policies(courses:)
    # Course post policies default to automatic
    created_at = Time.zone.now
    course_post_policy_records = courses.map do |course|
      {
        assignment_id: nil,
        course_id: course.id,
        created_at: created_at,
        post_manually: false,
        updated_at: created_at
      }
    end

    PostPolicy.bulk_insert(course_post_policy_records)
  end
end
