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

module Factories
  def lti_result_model(li_result_overrides = {})
    course = li_result_overrides.fetch(
      :course,
      li_result_overrides[:assignment]&.course || course_factory(active_course: true)
    )
    user = line_item_user(li_result_overrides, course)
    li = lti_result_line_item(li_result_overrides, course)
    Lti::Result.create!(line_item_params(li_result_overrides, user, li))
  end

  private

  def lti_result_line_item(li_result_overrides, course)
    li_result_overrides[:line_item] ||
      line_item_model(
        assignment: li_result_overrides[:assignment] ||
          assignment_model(
            course: course,
            points_possible: li_result_overrides.fetch(:result_maximum, 10)
          )
      )
  end

  def line_item_user(li_result_overrides, course)
    li_result_overrides[:user] ||
      create_users_in_course(course, 1, return_type: :record).first
  end

  def lti_result_submission(li_result_overrides, user, li)
    return unless li.assignment_line_item?
    submission = li.assignment.submissions.find_by(user: user) ||
                 graded_submission_model({ assignment: li.assignment, user: user })
    submission.update(score: li_result_overrides[:result_score]) if li_result_overrides[:result_score]
    submission
  end

  def line_item_params(li_result_overrides, user, li)
    time = Time.zone.now
    submission = lti_result_submission(li_result_overrides, user, li)
    {
      activity_progress: li_result_overrides.fetch(:activity_progress, 'Completed'),
      grading_progress: li_result_overrides.fetch(:grading_progress, 'FullyGraded'),
      line_item: li,
      user: user,
      submission: submission,
      result_score: li_result_overrides[:result_score],
      result_maximum: li_result_overrides[:result_maximum],
      updated_at: li_result_overrides.fetch(:updated_at, time),
      created_at: time,
      comment: li_result_overrides[:comment]
    }
  end
end
