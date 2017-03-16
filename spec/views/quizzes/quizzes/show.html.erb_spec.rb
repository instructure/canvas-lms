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
    assign(:quiz, @course.quizzes.create!)
    render "quizzes/quizzes/show"
    expect(response).not_to be_nil
  end

  it "should render a notice instead of grades if muted" do
    course_with_student(:active_all => true)
    quiz = @course.quizzes.create
    quiz.workflow_state = "available"
    quiz.save!
    quiz.reload
    quiz.assignment.mute!
    quiz.assignment.grade_student(@student, grade: 5, grader: @teacher)
    submission = quiz.quiz_submissions.create
    submission.score = 5
    submission.user = @student
    submission.attempt = 1
    submission.workflow_state = "complete"
    submission.save
    assign(:quiz, quiz)
    assign(:submission, submission)
    view_context
    render "quizzes/quizzes/show"
    expect(response).to have_tag ".muted-notice"
    true
  end

  it "doesn't warn students if quiz is published" do
    course_with_student(:active_all => true)
    quiz = @course.quizzes.build
    quiz.publish!
    assign(:quiz, quiz)
    view_context
    render "quizzes/quizzes/show"
    expect(response).not_to have_tag ".unpublished_warning"
  end

  it "should show header bar and publish button" do
    course_with_teacher(:active_all => true)
    assign(:quiz, @course.quizzes.create!)

    view_context
    render "quizzes/quizzes/show"

    expect(response).to have_tag ".header-bar"
    expect(response).to have_tag "#quiz-publish-link"
  end

  it "should show unpublished quiz changes to instructors" do
    course_with_teacher(:active_all => true)
    @quiz = @course.quizzes.create!
    @quiz.workflow_state = "available"
    @quiz.save!
    @quiz.publish!
    Quizzes::Quiz.mark_quiz_edited(@quiz.id)
    @quiz.reload
    assign(:quiz, @quiz)

    view_context
    render "quizzes/quizzes/show"

    expect(response).to have_tag ".unsaved_quiz_warning"
    expect(response).not_to have_tag ".unpublished_quiz_warning"
  end

  it "should hide points possible for ungraded surveys" do
    points = 5

    course_with_teacher(active_all: true)
    @quiz = @course.quizzes.create!(quiz_type: "survey", points_possible: points)

    assign(:quiz, @quiz)
    view_context
    render "quizzes/quizzes/show"

    doc = Nokogiri::HTML(response)
    doc.css(".control-group .controls .value").each do |node|
        expect(node.content).not_to include("#{points}") if node.parent.parent.content.include? "Points"
    end
  end

  it 'should render teacher partial for teachers' do
    course_with_teacher(active_all: true)
    view_context
    assign(:quiz, @course.quizzes.create!)
    render 'quizzes/quizzes/show'
    expect(view).to have_rendered '/quizzes/quizzes/_quiz_show_teacher'
    expect(view).not_to have_rendered '/quizzes/quizzes/_quiz_show_student'
  end

  it 'should render student partial for students' do
    course_with_student(active_all: true)
    quiz = @course.quizzes.build
    quiz.publish!
    assign(:quiz, quiz)
    view_context
    render 'quizzes/quizzes/show'
    expect(view).to have_rendered '/quizzes/quizzes/_quiz_show_student'
    expect(view).not_to have_rendered '/quizzes/quizzes/_quiz_show_teacher'
  end

  it 'should render draft version warning' do
    course_with_student(active_all: true)
    quiz = @course.quizzes.create
    quiz.workflow_state = 'available'
    quiz.save!
    quiz.reload
    quiz.assignment.mute!
    quiz.assignment.grade_student(@student, grade: 5, grader: @teacher)
    submission = quiz.quiz_submissions.create
    submission.score = 5
    submission.user = @student
    submission.attempt = 1
    submission.workflow_state = 'complete'
    submission.save
    assign(:quiz, quiz)
    assign(:submission, submission)
    params[:preview] = true
    view_context
    render 'quizzes/quizzes/show'

    expect(response).to include 'preview of the draft version'
  end
end

