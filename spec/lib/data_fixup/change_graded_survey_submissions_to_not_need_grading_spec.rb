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

    submission.reload.should be_completed
    submission.submission.should be_graded

    teacher_in_course(course: @course, active_all: true)
    @teacher.assignments_needing_grading.should_not include @quiz.assignment

  end

end
