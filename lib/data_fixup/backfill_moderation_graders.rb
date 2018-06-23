#
# Copyright (C) 2018 - present Instructure, Inc.
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

module DataFixup::BackfillModerationGraders
  def self.run(start_at, end_at)
    assignments = Assignment.where(id: start_at..end_at).where(moderated_grading: true).where("grader_count = 0 or grader_count is null")

    courses = assignments.distinct.pluck(:context_id)
    return if courses.blank?

    # Find all provisional graders for this batch of assignments
    graders = ModeratedGrading::ProvisionalGrade.joins(:submission).
      where("submissions.assignment_id IN (?)", assignments.select(:id)).
      pluck("distinct submissions.assignment_id, moderated_grading_provisional_grades.scorer_id")
    created_at = Time.zone.now

    Assignment.transaction do
      unless graders.blank?
        # generate unique anonymous ids for each grader
        existing_anonymous_ids = Hash.new { |hsh, key| hsh[key] = [] }
        graders.map! do |assignment_id, grader_id|
          anonymous_id = Anonymity.generate_id(existing_ids: existing_anonymous_ids[assignment_id])
          existing_anonymous_ids[assignment_id] << anonymous_id
          {
            anonymous_id: anonymous_id,
            assignment_id: assignment_id,
            user_id: grader_id,
            created_at: created_at,
            updated_at: created_at
          }
        end
        ModerationGrader.bulk_insert(graders)

        existing_anonymous_ids.each do |assignment_id, grader_ids|
          Assignment.where(id: assignment_id).update_all(grader_count: [grader_ids.length, 2].max, updated_at: created_at)
        end
      end

      # update remaining assignments with default 2 grader count
      assignments.update_all(grader_count: 2, updated_at: created_at)

      # Turn on moderated_grading feature flag for all courses of these assignments
      courses.map! do |course_id|
        vals = [
          Course.connection.quote(course_id),
          Course.connection.quote('Course'),
          Course.connection.quote('moderated_grading'),
          Course.connection.quote('on'),
          Course.connection.quote(created_at),
          Course.connection.quote(created_at)
        ]
        "(#{vals.join(',')})"
      end
      ActiveRecord::Base.connection.exec_insert <<~SQL
        INSERT INTO #{FeatureFlag.quoted_table_name}
          (context_id, context_type, feature, state, created_at, updated_at) VALUES #{courses.join(',')}
          ON CONFLICT (context_id, context_type, feature) DO UPDATE SET
            state = excluded.state,
            updated_at = excluded.updated_at
          WHERE feature_flags.state <> excluded.state
      SQL
    end
  end
end
