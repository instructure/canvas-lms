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

require "spec_helper"

describe GradeChangeAuditApiController do
  let_once(:admin) { account_admin_user }
  let_once(:course) { Course.create! }
  let_once(:teacher) { course_with_user("TeacherEnrollment", name: "Teacher", course: course, active_all: true).user }
  let_once(:student) { course_with_user("StudentEnrollment", name: "Student", course: course, active_all: true).user }
  let_once(:assignment) { course.assignments.create!(name: "an assignment") }
  let(:events_for_assignment) do
    json_parse(response.body).fetch("events").select do |event|
      event.fetch("links").fetch("assignment") == assignment.id
    end
  end
  let(:student_ids) { events_for_assignment.map { |event| event.fetch("links").fetch("student") }.compact }

  before :each do
    user_session(admin)
  end

  describe "GET for_assignment" do
    let(:params) { { assignment_id: assignment.id } }

    before :each do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get :for_assignment, params: params
      expect(student_ids).to include(student.id)
    end

    context "when assignment is anonymous and muted" do
      before :each do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      it "returns events" do
        get :for_assignment, params: params
        # The >= 2 is because there are at least events from grade_student of
        # score 100 and grade_student of score 99, but setting the assignment
        # to anonymous_grading also duplicated events. That behavior is
        # unwanted and should be removed in a later patchset.
        expect(events_for_assignment.count).to be >= 2
      end

      it "returns events without the student id included" do
        get :for_assignment, params: params
        expect(student_ids).to be_empty
      end
    end
  end

  describe "GET for_course" do
    let(:params) { { course_id: course.id } }

    before :each do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get :for_course, params: params
      expect(student_ids).to include(student.id)
    end

    context "when assignment is anonymous and muted" do
      before :each do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      it "returns events" do
        get :for_course, params: params
        expect(events_for_assignment.count).to be >= 2
      end

      it "returns events without the student id included" do
        get :for_course, params: params
        expect(student_ids).to be_empty
      end
    end
  end

  describe "GET for_student" do
    let(:params) { { student_id: student.id } }

    before :each do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get :for_student, params: params
      expect(student_ids).to include(student.id)
    end

    context "when assignment is anonymous and muted" do
      before :each do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      it "returns no events" do
        get :for_student, params: params
        expect(events_for_assignment).to be_empty
      end
    end
  end

  describe "GET for_grader" do
    let(:params) { { grader_id: teacher.id } }

    before :each do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get :for_grader, params: params
      expect(student_ids).to include(student.id)
    end

    context "when assignment is anonymous and muted" do
      before :each do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      it "returns events" do
        get :for_grader, params: params
        expect(events_for_assignment.count).to be >= 2
      end

      it "returns events without the student id included" do
        get :for_grader, params: params
        expect(student_ids).to be_empty
      end
    end
  end

  describe "GET for_course_and_other_parameters" do
    let(:params) do
      {
        course_id: course.id,
        grader_id: teacher.id,
        assignment_id: assignment.id,
        student_id: student.id
      }
    end

    before :each do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get :for_course_and_other_parameters, params: params
      expect(student_ids).to include(student.id)
    end

    context "when assignment is anonymous and muted" do
      before :each do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      context "and student_id present in params" do
        it "returns no events" do
          get :for_course_and_other_parameters, params: params
          expect(events_for_assignment).to be_empty
        end
      end

      context "and student_id is not present in params" do
        it "returns events" do
          get :for_course_and_other_parameters, params: params.except(:student_id)
          expect(events_for_assignment.count).to be >= 2
        end

        it "returns events without the student id included" do
          get :for_course_and_other_parameters, params: params
          expect(student_ids).to be_empty
        end
      end
    end
  end
end
