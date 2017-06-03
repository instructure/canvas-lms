#
# Copyright (C) 2013 - present Instructure, Inc.
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

require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) +
 '/../../../lib/data_fixup/change_graded_survey_submissions_to_not_need_grading')

describe DataFixup::ChangeGradedSurveySubmissionsToNotNeedGrading do

  subject do
    DataFixup::ChangeGradedSurveySubmissionsToNotNeedGrading
  end

  it "changes graded survey submissions to complete workflow_state" do
    course_with_student(active_all: true)
    course_quiz(course: @course)

    @quiz.quiz_type = 'graded_survey'
    @quiz.publish!

    submission = @quiz.generate_submission(@student)
    submission.submission = submission.assignment.find_or_create_submission(@student.id)
    Quizzes::SubmissionGrader.new(submission).grade_submission(grade: 15)
    submission.workflow_state = 'pending_review'
    submission.score = 10
    submission.save!

    subject.run

    expect(submission.reload).to be_completed
    expect(submission.submission).to be_graded

    teacher_in_course(course: @course, active_all: true)
    expect(@teacher.assignments_needing_grading).not_to include @quiz.assignment

  end

end
