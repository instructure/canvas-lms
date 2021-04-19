# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SubmissionSearch do
  let_once(:course) { Course.create!(workflow_state: "available") }
  let_once(:jonah) { User.create!(name: 'Jonah Jameson') }
  let_once(:amanda) { User.create!(name: 'Amanda Jones') }
  let_once(:mandy) { User.create!(name: 'Mandy Miller') }
  let_once(:james) { User.create!(name: 'James Peterson') }
  let_once(:peter) { User.create!(name: 'Peter Piper') }
  let_once(:students) { [jonah, amanda, mandy, james, peter] }
  let_once(:teacher) do
    teacher = User.create!(name: 'Teacher Miller')
    TeacherEnrollment.create!(user: teacher, course: course, workflow_state: 'active')
    teacher
  end
  let_once(:assignment) do
    Assignment.create!(
      course: course,
      workflow_state: 'active',
      submission_types: 'online_text_entry',
      title: 'an assignment',
      description: 'the body'
    )
  end

  before :once do
    students.each do |student|
      StudentEnrollment.create!(user: student, course: course, workflow_state: 'active')
    end
  end

  it 'finds all submissions' do
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{field: 'username'}]).search
    expect(results.preload(:user).map(&:user)).to eq students
  end

  it 'finds submissions with user name search' do
    results = SubmissionSearch.new(assignment, teacher, nil,
      user_search: 'man',
      order_by: [{field: 'username', direction: 'descending'}]).search
    expect(results).to eq [
      Submission.find_by(user: mandy),
      Submission.find_by(user: amanda),
    ]
  end

  it 'filters for the specified workflow state' do
    assignment.submit_homework(amanda, submission_type: 'online_text_entry', body: 'submission')
    results = SubmissionSearch.new(assignment, teacher, nil, states: ['submitted']).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it 'filters results to specified sections' do
    section = course.course_sections.create!
    StudentEnrollment.create!(user: amanda, course: course, course_section: section, workflow_state: 'active')
    results = SubmissionSearch.new(assignment, teacher, nil, section_ids: [section.id]).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end


  it 'filters by the enrollment type' do
    fake_student = assignment.course.student_view_student
    results = SubmissionSearch.new(assignment, teacher, nil, enrollment_types: ['StudentEnrollment']).search
    expect(results).not_to include Submission.find_by(user: fake_student)
  end

  it 'filters by scored less than' do
    assignment.grade_student(amanda, score: 42, grader: teacher)
    assignment.grade_student(mandy, score: 10, grader: teacher)
    results = SubmissionSearch.new(assignment, teacher, nil, scored_less_than: 42).search
    expect(results).to eq [Submission.find_by(user: mandy)]
  end

  it 'filters by scored greater than' do
    assignment.grade_student(amanda, score: 42, grader: teacher)
    assignment.grade_student(mandy, score: 10, grader: teacher)
    results = SubmissionSearch.new(assignment, teacher, nil, scored_more_than: 10).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it 'filters by late' do
    late_student = student_in_course(course: course, active_all: true).user
    assignment = course.assignments.create!(name: "assignment", points_possible: 10, due_at: 2.days.ago)
    submission = assignment.submit_homework(late_student, body: 'asdf', submitted_at: 1.day.ago)
    results = SubmissionSearch.new(assignment, teacher, nil, late: true).search
    expect(results).to eq [submission]
  end

  it 'filters by needs_grading' do
    submission = assignment.submit_homework(amanda, body: 'asdf')
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: 'needs_grading').search
    expect(results).to eq [submission]
  end

  it 'filters by excused' do
    submission = Submission.find_by(user: jonah)
    submission.excused = true
    submission.save!
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: 'excused').search
    expect(results).to eq [submission]
  end

  it 'filters by needs_review' do
    submission = Submission.find_by(user: peter)
    submission.workflow_state = 'pending_review'
    submission.save!
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: 'needs_review').search
    expect(results).to eq [submission]
  end

  it 'filters by graded' do
    submission = Submission.find_by(user: mandy)
    submission.workflow_state = 'graded'
    submission.save!
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: 'graded').search
    expect(results).to eq [submission]
  end

  it "limits results to just the user's submission if the user is a student" do
    results = SubmissionSearch.new(assignment, amanda, nil, {}).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it "returns nothing to randos" do
    rando = User.create!
    results = SubmissionSearch.new(assignment, rando, nil, {}).search
    expect(results).to eq []
  end

  # order by username tested above
  it 'orders by submission score' do
    assignment.grade_student(peter, score: 1, grader: teacher)
    assignment.grade_student(amanda, score: 2, grader: teacher)
    assignment.grade_student(james, score: 3, grader: teacher)
    results = SubmissionSearch.new(assignment, teacher, nil, scored_more_than: 0, order_by: [{field: 'score'}]).search
    expect(results.preload(:user).map(&:user)).to eq [peter, amanda, james]
  end

  it 'orders by submission date' do
    Timecop.freeze do
      assignment.submit_homework(peter, submission_type: 'online_text_entry', body: 'homework', submitted_at: Time.zone.now)
      assignment.submit_homework(amanda, submission_type: 'online_text_entry', body: 'homework', submitted_at: Time.zone.now + 1.hour)
      results = SubmissionSearch.new(assignment, teacher, nil, states: 'submitted', order_by: [{field: 'submitted_at'}]).search
      expect(results.preload(:user).map(&:user)).to eq [peter, amanda]
    end
  end

  it 'orders by multiple fields' do
    assignment.grade_student(peter, score: 1, grader: teacher)
    assignment.grade_student(amanda, score: 1, grader: teacher)
    assignment.grade_student(james, score: 3, grader: teacher)
    results = SubmissionSearch.new(assignment, teacher, nil,
      scored_more_than: 0,
      order_by: [
        {field: 'score', direction: 'descending'},
        {field: 'username', direction: 'ascending'}
      ]
    ).search
    expect(results.preload(:user).map(&:user)).to eq [james, amanda, peter]
  end

  # TODO: implement
  it 'filters results to assigned users if assigned_only filter is set'
  it 'filters results to specified groups'
  it 'orders by submission status' # missing, late, etc.
end
