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

require "spec_helper"

describe GradeChangeAuditApiController do
  let_once(:admin) { account_admin_user }
  let_once(:course) { Course.create! }
  let_once(:teacher) { course_with_user("TeacherEnrollment", name: "Teacher", course:, active_all: true).user }
  let_once(:student) { course_with_user("StudentEnrollment", name: "Student", course:, active_all: true).user }
  let_once(:assignment) { course.assignments.create!(name: "an assignment") }

  let(:returned_events) { json_parse(response.body).fetch("events") }
  let(:events_for_assignment) do
    returned_events.select do |event|
      event.fetch("links").fetch("assignment") == assignment.id
    end
  end
  let(:student_ids) { events_for_assignment.filter_map { |event| event.fetch("links").fetch("student") } }

  before do
    user_session(admin)
  end

  describe "GET for_assignment" do
    let(:params) { { assignment_id: assignment.id } }

    before do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events" do
      get(:for_assignment, params:)
      expect(events_for_assignment.count).to eq(1)
    end

    it "returns events with the student's id included" do
      get(:for_assignment, params:)
      expect(student_ids).to include(student.id.to_s)
    end

    describe "override grade change events" do
      before do
        override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
          grader: teacher,
          old_grade: nil,
          old_score: nil,
          score: student.enrollments.first.find_score
        )
        Auditors::GradeChange.record(override_grade_change:)
      end

      let(:returned_event_assignment_ids) do
        get :for_course, params: { course_id: course.id }
        events = json_parse(response.body).fetch("events")

        events.map { |event| event.dig("links", "assignment") }.uniq
      end

      it "includes override grade change events in the results when the course allows overrides" do
        course.enable_feature!(:final_grades_override)
        course.allow_final_grade_override = true
        course.save!

        expect(returned_event_assignment_ids).to contain_exactly(assignment.id, nil)
      end

      it "excludes override grade change events from the results when the course does not allow overrides" do
        expect(returned_event_assignment_ids).to contain_exactly(assignment.id)
      end

      it "explicitly filters out override events when they are not supposed to be shown" do
        expect(BookmarkedCollection).to receive(:filter).once
        get :for_course, params: { course_id: course.id }
      end
    end

    describe "current_grade" do
      let(:returned_events) do
        get :for_course, params: { course_id: course.id, include: ["current_grade"] }
        json_parse(response.body).fetch("events")
      end
      let(:current_grades) { returned_events.pluck("grade_current") }

      context "for assignment grade changes" do
        before do
          assignment.grade_student(student, grader: teacher, score: 75)
        end

        it "is set to the submission's current grade" do
          expect(current_grades.uniq).to contain_exactly("75")
        end

        it "is not present if there is no current grade" do
          assignment.grade_student(student, grader: teacher, score: nil)
          expect(returned_events.any? { |event| event.key?("current_grade") }).to be false
        end
      end

      context "for override grade changes" do
        before do
          @course.enable_feature!(:final_grades_override)
          @course.allow_final_grade_override = true
          @course.save!
        end

        let(:returned_events) do
          get :for_course, params: { course_id: course.id, include: ["current_grade"] }
          json_parse(response.body).fetch("events").filter { |event| event["course_override_grade"] }
        end

        let(:course_score) { student.enrollments.first.find_score }

        def apply_override_score(score_record: course_score, new_score:)
          old_grade = score_record.override_grade
          old_score = score_record.override_score

          score_record.update!(override_score: new_score)
          override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
            grader: teacher,
            old_grade:,
            old_score:,
            score: score_record
          )
          Auditors::GradeChange.record(override_grade_change:)
        end

        context "for scores not in a grading period" do
          before do
            apply_override_score(new_score: 90.0)
            apply_override_score(new_score: 70.0)
          end

          it "is set to the student's current override grade if the course has a grading scheme" do
            @course.grading_standard_enabled = true
            @course.save!
            expect(returned_events.pluck("grade_current").uniq).to contain_exactly("C-")
          end

          it "is set to the student's current override score if the course has no grading scheme" do
            expect(returned_events.pluck("grade_current").uniq).to contain_exactly("70%")
          end

          it "is not present if there is no override grade for the student" do
            apply_override_score(new_score: nil)
            expect(returned_events.pluck("grade_current").uniq).to contain_exactly(nil)
          end
        end

        context "for scores in a grading period" do
          let(:grading_period) do
            grading_period_group = @course.account.grading_period_groups.create!
            now = Time.zone.now

            grading_period_group.grading_periods.create!(
              close_date: 1.week.from_now(now),
              end_date: 1.week.from_now(now),
              start_date: 1.week.ago(now),
              title: "a"
            )
          end
          let(:grading_period_score) do
            Score.create!(grading_period:, enrollment: student.enrollments.first)
          end

          before do
            apply_override_score(score_record: grading_period_score, new_score: 90.0)
            apply_override_score(score_record: grading_period_score, new_score: 70.0)
          end

          it "is set to the student's current override grade if the course has a grading scheme" do
            @course.grading_standard_enabled = true
            @course.save!
            expect(returned_events.pluck("grade_current").uniq).to contain_exactly("C-")
          end

          it "is set to the student's current override score if the course has no grading scheme" do
            apply_override_score(score_record: grading_period_score, new_score: 70.0)
            expect(returned_events.pluck("grade_current").uniq).to contain_exactly("70%")
          end

          it "is not present if there is no override grade for the student" do
            apply_override_score(score_record: grading_period_score, new_score: nil)
            expect(returned_events.pluck("grade_current").uniq).to contain_exactly(nil)
          end
        end
      end
    end
  end

  describe "GET for_course" do
    let(:params) { { course_id: course.id } }

    before do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get(:for_course, params:)
      expect(student_ids).to include(student.id.to_s)
    end

    context "when assignment is anonymous and muted" do
      before do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      it "returns events" do
        get(:for_course, params:)
        expect(events_for_assignment.count).to be >= 2
      end

      it "returns events without the student id included" do
        get(:for_course, params:)
        expect(student_ids).to be_empty
      end
    end
  end

  describe "GET for_student" do
    let(:params) { { student_id: student.id } }

    before do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get(:for_student, params:)
      expect(student_ids).to include(student.id.to_s)
    end

    context "when assignment is anonymous and muted" do
      before do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      it "returns no events" do
        get(:for_student, params:)
        expect(events_for_assignment).to be_empty
      end
    end
  end

  describe "GET for_grader" do
    let(:params) { { grader_id: teacher.id } }

    before do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get(:for_grader, params:)
      expect(student_ids).to include(student.id.to_s)
    end

    context "when assignment is anonymous and muted" do
      before do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      it "returns events" do
        get(:for_grader, params:)
        expect(events_for_assignment.count).to be >= 2
      end

      it "returns events without the student id included" do
        get(:for_grader, params:)
        expect(student_ids).to be_empty
      end
    end
  end

  describe "GET query" do
    let(:params) do
      {
        course_id: course.id,
        grader_id: teacher.id,
        assignment_id: assignment.id,
        student_id: student.id
      }
    end

    before do
      assignment.grade_student(student, grader: teacher, score: 100)
    end

    it "returns events with the student's id included" do
      get(:query, params:)
      expect(student_ids).to include(student.id.to_s)
    end

    context "when assignment is anonymous and muted" do
      before do
        assignment.update!(anonymous_grading: true)
        assignment.update!(muted: true)
        assignment.reload
        assignment.grade_student(student, grader: teacher, score: 99)
      end

      context "and student_id present in params" do
        it "returns no events" do
          get(:query, params:)
          expect(events_for_assignment).to be_empty
        end
      end

      context "and student_id is not present in params" do
        it "returns events" do
          get :query, params: params.except(:student_id)
          expect(events_for_assignment.count).to be >= 2
        end

        it "returns events without the student id included" do
          get(:query, params:)
          expect(student_ids).to be_empty
        end
      end
    end

    describe "filtering by assignment" do
      let(:returned_assignment_ids) { returned_events.map { |event| event.dig("links", "assignment") } }

      before(:once) do
        assignment.grade_student(student, score: 10, grader: teacher)

        @override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
          grader: teacher,
          old_grade: nil,
          old_score: nil,
          score: student.enrollments.first.find_score
        )
      end

      before do
        # FIXME: this should be in before(:once) but Auditors.write_to_postgres? isn't stubbed there
        Auditors::GradeChange.record(override_grade_change: @override_grade_change)
      end

      context "final grade override in Gradebook History" do
        before(:once) do
          course.enable_feature!(:final_grades_override)
          course.allow_final_grade_override = true
          course.save!
        end

        it "returns both assignment and override grade changes when no assignment_id value is specified" do
          get :query, params: params.except(:assignment_id)
          expect(returned_assignment_ids.uniq).to contain_exactly(assignment.id, nil)
        end

        it "returns only override grade changes when an assignment ID of 'override' is specified" do
          get :query, params: params.merge({ assignment_id: "override" })
          expect(returned_assignment_ids).to contain_exactly(nil)
        end

        it "omits override grade changes when the course does not allow final grade overrides" do
          course.allow_final_grade_override = false
          course.save!

          get :query, params: params.except(:assignment_id)
          expect(returned_assignment_ids.uniq).to contain_exactly(assignment.id)
        end
      end

      it "returns only grade changes for the assignment when a legitimate assignment ID is specified" do
        get(:query, params:)
        expect(returned_assignment_ids.uniq).to contain_exactly(assignment.id)
      end
    end

    describe "filtering by student" do
      let(:returned_assignment_ids) { returned_events.map { |event| event.dig("links", "assignment") } }

      before do
        override_grade_change = Auditors::GradeChange::OverrideGradeChange.new(
          grader: teacher,
          old_grade: nil,
          old_score: nil,
          score: student.enrollments.first.find_score
        )
        Auditors::GradeChange.record(override_grade_change:)
      end

      it "returns override grade changes" do
        get :query, params: { student_id: student.id }
        expect(returned_assignment_ids).to contain_exactly(assignment.id, nil)
      end
    end
  end
end
