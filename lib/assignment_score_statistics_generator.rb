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
    # The 60s delay below is in case lots of little grade calculator
    # updates come close together. Since we're a singleton, they won't
    # queue up additional jobs if one exists. Our goal is to try to
    # not run this potentially expensive query constantly.
    send_later_if_production_enqueue_args(
      :update_score_statistics,
      {
        singleton: "AssignmentScoreStatisticsGenerator:#{course_id}",
        run_at: 60.seconds.from_now
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
    statistics = course.assignments.published.preload(score_statistic: :assignment).
      joins(:submissions).
      joins("INNER JOIN #{Enrollment.quoted_table_name} enrollments ON submissions.user_id = enrollments.user_id").
      merge(course.all_enrollments.of_student_type.active_or_pending).
      merge(Submission.not_placeholder.where("submissions.excused IS NOT TRUE")).
      where.not(submissions: { score: nil }).
      where(submissions: { workflow_state: 'graded' }).
      group("assignments.id").
      select("assignments.id, max(score) max, min(score) min, avg(score) avg, count(submissions.id) count")

    statistics.map do |assignment|
      assignment_stats = {
        maximum: assignment.max,
        minimum: assignment.min,
        mean: assignment.avg,
        count: assignment.count
      }

      if assignment.score_statistic.present?
        assignment.score_statistic.update!(assignment_stats)
      else
        assignment.create_score_statistic!(assignment_stats)
      end
    end
  end
end
