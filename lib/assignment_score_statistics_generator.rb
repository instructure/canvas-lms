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

class AssignmentScoreStatisticsGenerator
  def self.update_score_statistics_in_singleton(course_id)
    # The delay below is in case lots of little grade calculator
    # updates come close together. Since we're a singleton, they won't
    # queue up additional jobs if one exists. Our goal is to try to
    # not run this potentially expensive query constantly.
    # The random part of the delay is to make it not run for all courses in a
    # term or all courses in a grading period at the same time.
    min = Setting.get("minimum_seconds_wait_for_grade_statistics", 10).to_i
    max = Setting.get("maximum_seconds_wait_for_grade_statistics", 130).to_i
    send_later_if_production_enqueue_args(
      :update_score_statistics,
      {
        singleton: "AssignmentScoreStatisticsGenerator:#{course_id}",
        run_at: rand(min..max).seconds.from_now,
        on_conflict: :loose
      },
      course_id
    )
  end

  def self.update_score_statistics(course_id)
    course = Course.find(course_id)

    # performance note: There is an overlap between
    # Submission.not_placeholder and the submission where clause.
    #
    # note: because a score is needed for max/min/ave we are not filtering
    # by assignment_student_visibilities, if a stat is added that doesn't
    # require score then add a filter when the DA feature is on
    statistics = Shackles.activate(:slave) do
      course.assignments.published.preload(score_statistic: :assignment).
        joins(:submissions).
        joins("INNER JOIN #{Enrollment.quoted_table_name} enrollments ON submissions.user_id = enrollments.user_id").
        merge(course.all_enrollments.of_student_type.active_or_pending).
        merge(Submission.not_placeholder.where("submissions.excused IS NOT TRUE")).
        where.not(submissions: { score: nil }).
        where(submissions: { workflow_state: 'graded' }).
        group("assignments.id").
        select("assignments.id, max(score) max, min(score) min, avg(score) avg, count(submissions.id) count").to_a
    end

    connection = ScoreStatistic.connection
    now = connection.quote(Time.now.utc)
    bulk_values = statistics.map do |assignment|
      values =
        [
          connection.quote(assignment.id),
          connection.quote(assignment.max),
          connection.quote(assignment.min),
          connection.quote(assignment.avg),
          connection.quote(assignment.count),
          now,
          now
        ].join(',')
      "(#{values})"
    end

    bulk_values.each_slice(100) do |bulk_slice|
      connection.execute(<<~SQL)
        INSERT INTO #{ScoreStatistic.quoted_table_name}
          (assignment_id, maximum, minimum, mean, count, created_at, updated_at)
        VALUES #{bulk_slice.join(',')}
        ON CONFLICT (assignment_id)
        DO UPDATE SET
           minimum = excluded.minimum,
           maximum = excluded.maximum,
           mean = excluded.mean,
           count = excluded.count,
           updated_at = excluded.updated_at
      SQL
    end
  end
end
