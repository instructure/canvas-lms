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

class SpeedGrader::Submission
  def initialize(submission:, current_user:, provisional_grade:)
    @submission = submission
    @current_user = current_user
    @provisional_grade = provisional_grade
  end

  def comments
    comments = if submission.assignment.grades_published?
      submission.submission_comments
    elsif grader_comments_hidden?
      (provisional_grade || submission).submission_comments
    else
      submission.all_submission_comments
    end
    comments = comments.for_groups if submission.assignment.grade_as_group?
    comments
  end

  private

  def grader_comments_hidden?
    !submission.assignment.can_view_other_grader_comments?(current_user)
  end

  attr_reader :submission, :current_user, :provisional_grade
end
