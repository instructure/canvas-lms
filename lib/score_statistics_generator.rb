# frozen_string_literal: true

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

class ScoreStatisticsGenerator
  def self.update_score_statistics_in_singleton(course)
    course_global_id = course.global_id
    global_root_account_id = course.global_root_account_id

    # The delay below is in case lots of little grade calculator
    # updates come close together. Since we're a singleton, they won't
    # queue up additional jobs if one exists. Our goal is to try to
    # not run this potentially expensive query constantly.
    # The random part of the delay is to make it not run for all courses in a
    # term or all courses in a grading period at the same time.
    min = 10
    max = 130
    delay_if_production(singleton: "ScoreStatisticsGenerator:#{course_global_id}",
                        n_strand: ["ScoreStatisticsGenerator", global_root_account_id],
                        run_at: rand(min..max).seconds.from_now,
                        on_conflict: :loose)
      .update_score_statistics(course.id)
  end

  def self.update_score_statistics(course_id)
    root_account_id = Course.find_by(id: course_id)&.root_account_id

    # Only necessary in local dev because we are not running in a job
    GuardRail.activate(:primary) do
      update_assignment_score_statistics(course_id, root_account_id:)
      update_course_score_statistic(course_id)
    end
  end

  def self.update_assignment_score_statistics(course_id, root_account_id:)
    # NOTE: because a score is needed for max/min/ave we are not filtering
    # by assignment_student_visibilities, if a stat is added that doesn't
    # require score then add a filter when the DA feature is on
    statistics = GuardRail.activate(:secondary) do
      connection = ScoreStatistic.connection
      connection.select_all(<<~SQL.squish)
        WITH want_assignments AS (
          SELECT a.id, a.created_at
          FROM #{Assignment.quoted_table_name} a
          WHERE a.context_id = #{course_id} AND a.context_type = 'Course' AND a.workflow_state = 'published'
        ), interesting_submissions AS (
          SELECT s.assignment_id, s.user_id, s.score, a.created_at
          FROM #{Submission.quoted_table_name} s
          JOIN want_assignments a ON s.assignment_id = a.id
          WHERE
            s.excused IS NOT true
            AND s.score IS NOT NULL
            AND s.workflow_state = 'graded'
        ), want_users AS (
          SELECT e.user_id
          FROM #{Enrollment.quoted_table_name} e
          WHERE e.type = 'StudentEnrollment' AND e.course_id = #{course_id} AND e.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')
        )
        SELECT
          s.assignment_id AS id,
          MAX(s.score) AS max,
          MIN(s.score) AS min,
          AVG(s.score) AS avg,
          percentile_cont(0.25) WITHIN GROUP (ORDER BY s.score) AS lower_q,
          percentile_cont(0.5) WITHIN GROUP (ORDER BY s.score) AS median,
          percentile_cont(0.75) WITHIN GROUP (ORDER BY s.score) AS upper_q,
          COUNT(*) AS count
        FROM
          interesting_submissions s
        WHERE
          s.user_id IN (SELECT user_id FROM want_users)
        GROUP BY s.assignment_id
        ORDER BY MIN(s.created_at)
      SQL
    end

    connection = ScoreStatistic.connection
    now = connection.quote(Time.now.utc)
    bulk_values = statistics.map do |assignment|
      values =
        [
          assignment["id"],
          assignment["max"],
          assignment["min"],
          assignment["avg"],
          assignment["lower_q"],
          assignment["median"],
          assignment["upper_q"],
          assignment["count"],
          now,
          now,
          root_account_id
        ].join(",")
      "(#{values})"
    end

    bulk_values.each_slice(100) do |bulk_slice|
      connection.execute(<<~SQL.squish)
        INSERT INTO #{ScoreStatistic.quoted_table_name}
          (assignment_id, maximum, minimum, mean, lower_q, median, upper_q, count, created_at, updated_at, root_account_id)
        VALUES #{bulk_slice.join(",")}
        ON CONFLICT (assignment_id)
        DO UPDATE SET
           minimum = excluded.minimum,
           maximum = excluded.maximum,
           mean = excluded.mean,
           lower_q = excluded.lower_q,
           median = excluded.median,
           upper_q = excluded.upper_q,
           count = excluded.count,
           updated_at = excluded.updated_at,
           root_account_id = #{root_account_id}
      SQL
    end
  end

  def self.update_course_score_statistic(course_id)
    current_scores = []
    enrollment_ids = []
    GuardRail.activate(:secondary) do
      StudentEnrollment.select(:id, :user_id).not_fake.where(course_id:, workflow_state: [:active, :invited])
                       .find_in_batches { |batch| enrollment_ids.concat(batch) }
      # The grade calculator ensures all enrollments for the same user have the same score, so we only need one
      # enrollment_id for our later score query
      enrollment_ids = enrollment_ids.uniq(&:user_id).map(&:id)

      enrollment_ids.each_slice(1000) do |enrollment_slice|
        current_scores.concat(Score.where(enrollment_id: enrollment_slice, course_score: true).pluck(:current_score).compact)
      end
    end

    score_count = current_scores.length

    if score_count.zero?
      CourseScoreStatistic.where(course_id:).delete_all
      return
    end

    average = current_scores.sum(&:to_d) / BigDecimal(score_count)

    # This is a safeguard to avoid blowing up due to database storage which is set to be a decimal with a precision of 8
    # and a scale of 2. And really, what are you even doing awarding 1,000,000% or over in a course?
    return if average > BigDecimal("999_999.99") || average < BigDecimal("-999_999.99")

    connection = CourseScoreStatistic.connection
    now = connection.quote(Time.now.utc)
    values = [
      connection.quote(course_id),
      connection.quote(average&.round(2)),
      connection.quote(score_count),
      now,
      now
    ].join(",")

    CourseScoreStatistic.connection.execute(<<~SQL.squish)
      INSERT INTO #{CourseScoreStatistic.quoted_table_name}
        (course_id, average, score_count, created_at, updated_at)
      VALUES (#{values})
      ON CONFLICT (course_id)
      DO UPDATE SET
        average = excluded.average,
        score_count = excluded.score_count,
        updated_at = excluded.updated_at
    SQL
  end
end
