#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../views_helper')

describe "/quizzes/quizzes/show" do
  it "should render" do
    course_with_student
    view_context
    ActiveRecord::Base.clear_cached_contexts
    assigns[:quiz] = @course.quizzes.create!
    render "quizzes/quizzes/show"
    response.should_not be_nil
  end

  it "should render a notice instead of grades if muted" do
    course_with_student_logged_in(:active_all => true)
    quiz = @course.quizzes.create
    quiz.workflow_state = "available"
    quiz.save!
    quiz.assignment = @course.assignments.create(:title => quiz.title, :due_at => quiz.due_at, :submission_types => 'online_quiz')
    quiz.assignment.mute!
    quiz.assignment.grade_student(@student, :grade => 5)
    submission = quiz.quiz_submissions.create
    submission.score = 5
    submission.user = @student
    submission.attempt = 1
    submission.workflow_state = "complete"
    submission.save
    assigns[:quiz] = quiz
    assigns[:submission] = submission
    view_context
    render "quizzes/quizzes/show"
    response.should have_tag ".muted-notice"
    true
  end

  it "doesn't warn students if quiz is published" do
    course_with_student_logged_in(:active_all => true)
    quiz = @course.quizzes.build
    quiz.publish!
    assigns[:quiz] = quiz
    view_context
    render "quizzes/quizzes/show"
    response.should_not have_tag ".unpublished_warning"
  end

  it "warns students if quiz is unpublished" do
    course_with_student_logged_in(:active_all => true)
    quiz = @course.quizzes.create!
    assigns[:quiz] = quiz
    view_context
    render "quizzes/quizzes/show"
    response.should have_tag ".unpublished_warning"
  end

  it "should show header bar and publish button if draft state enabled" do
    Account.default.enable_feature!(:draft_state)

    course_with_teacher_logged_in(:active_all => true)
    assigns[:quiz] = @course.quizzes.create!

    view_context
    render "quizzes/quizzes/show"

    response.should have_tag ".header-bar"
    response.should have_tag "#quiz-publish-link"
  end

end

