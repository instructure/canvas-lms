#
# Copyright (C) 2016 Instructure, Inc.
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

module DataFixup::PopulateScoresTable
  def self.run
    Course.find_each do |course|
      # find all effective due dates for assignments in this course
      assignment_due_dates_hash = EffectiveDueDates.for_course(course).to_hash([:grading_period_id])
      grading_periods = []
      students_by_gp = {}
      # find all grading periods that this course touches
      assignment_due_dates_hash.each do |_, students|
        students.each do |student_id, hsh|
          grading_period = hsh[:grading_period_id]
          next unless grading_period
          grading_periods << grading_period
          students_by_gp[grading_period] ||= []
          students_by_gp[grading_period] << student_id
        end
      end
      grading_periods.uniq!

      # run GradeCalculator per grading period to backfill Scores
      grading_periods.each do |grading_period|
        user_ids = students_by_gp[grading_period].uniq
        # only consider users who don't already have a Score object for this grading period
        user_ids = course.enrollments.joins("
          LEFT JOIN #{Score.quoted_table_name} scores ON
            scores.enrollment_id = enrollments.id AND
            scores.workflow_state <> 'deleted' AND
            scores.grading_period_id = #{grading_period}").
          where("enrollments.user_id IN (?) AND scores.id IS NULL", user_ids).
          distinct.pluck(:user_id)

        # compute and save score for each grading period of this course
        gc = GradeCalculator.new(user_ids, course, grading_period: GradingPeriod.find(grading_period))
        gc.compute_and_save_scores
      end

      # now we can just copy scores from the Enrollment objects for this
      # course to new Score objects for the overall course grade
      ActiveRecord::Base.connection.execute("
        INSERT INTO #{Score.quoted_table_name}
          (enrollment_id, grading_period_id, current_score, final_score, created_at, updated_at, workflow_state)
          SELECT
            e.id as enrollment_id,
            NULL as grading_period_id,
            e.computed_current_score as current_score,
            e.computed_final_score as final_score,
            e.graded_at as created_at,
            e.graded_at as updated_at,
            CASE e.workflow_state
              WHEN 'deleted' THEN 'deleted'
              ELSE 'active'
            END AS workflow_state
          FROM #{Enrollment.quoted_table_name} e
          LEFT OUTER JOIN #{Score.quoted_table_name} scores on
              scores.enrollment_id = e.id AND
              scores.grading_period_id IS NULL AND
              -- find active scores only, unless enrollment is deleted, then consider all scores
              scores.workflow_state <> COALESCE(NULLIF('deleted', e.workflow_state), 'impossible_state')
          WHERE
            e.course_id = #{course.id} AND
            e.type IN ('StudentEnrollment', 'StudentViewEnrollment') AND
            scores.id IS NULL
      ")
    end
  end
end
