#
# Copyright (C) 2015-2016 Instructure, Inc.
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

require_relative '../spec_helper'

require 'csv'

describe GradebookExporter do
  before(:once) do
    teacher_in_course active_all: true
  end

  describe "#to_csv" do
    let(:course) { @course }
    let(:teacher) { @teacher }

    def exporter(opts = {})
      GradebookExporter.new(course, @teacher, opts)
    end

    describe "default output with blank course" do
      subject(:csv)   { exporter.to_csv }

      it "produces a String" do
        expect(subject).to be_a String
      end

      it "is a csv with two rows" do
        expect(CSV.parse(subject).count).to be 2
      end

      it "is a csv with eight columns" do
        expect(CSV.parse(subject).transpose.count).to be 8
      end

      describe "default headers order" do
        let(:headers) { CSV.parse(subject, headers: true).headers }

        it("first column") { expect(headers[0]).to eq "Student" }
        it("second column") { expect(headers[1]).to eq "ID" }
        it("third column") { expect(headers[2]).to eq "SIS Login ID" }
        it("fourth column") { expect(headers[3]).to eq "Section" }
        it("fifth column") { expect(headers[4]).to eq "Current Points" }
        it("sixth column") { expect(headers[5]).to eq "Final Points" }
        it("seventh column") { expect(headers[6]).to eq "Current Score" }
        it("eigth column") { expect(headers[7]).to eq "Final Score" }
      end
    end

    context "a course has assignments with due dates" do
      before(:once) do
        @no_due_date_assignment = assignments.create! title: "no due date",
          points_possible: 10

        @past_assignment = assignments.create! due_at: 5.weeks.ago,
          title: "past",
          points_possible: 10

        @current_assignment = assignments.create! due_at: 1.weeks.from_now,
          title: "current",
          points_possible: 10

        @future_assignment = assignments.create! due_at: 8.weeks.from_now,
          title: "future",
          points_possible: 10

        student_in_course active_all: true

        @no_due_date_assignment.grade_student @student, grade: 1, grader: @teacher
        @past_assignment.grade_student @student, grade: 2, grader: @teacher
        @current_assignment.grade_student @student, grade: 3, grader: @teacher
        @future_assignment.grade_student @student, grade: 4, grader: @teacher
      end

      let(:assignments) { course.assignments }

      let!(:group) { Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(course) }

      let!(:first_period) do
        args = {
          start_date: 6.weeks.ago,
          end_date: 3.weeks.ago,
          title: "past grading period"
        }

        group.grading_periods.create! args
      end

      let!(:last_period) do
        args = {
          start_date: 3.weeks.ago,
          end_date: 3.weeks.from_now,
          title: "present day, present time"
        }

        group.grading_periods.create! args
      end

      let(:csv)     { exporter(grading_period_id: @grading_period_id).to_csv }
      let(:rows)    { CSV.parse(csv, headers: true) }
      let(:headers) { rows.headers }

      describe "when multiple grading periods is on" do
        before { @grading_period_id = last_period.id }

        describe "assignments in the selected grading period are exported" do
          let!(:enable_mgp) do
            course.enable_feature!(:multiple_grading_periods)
          end

          it "exports selected grading period's assignments" do
            expect(headers).to include @no_due_date_assignment.title_with_id,
                                       @current_assignment.title_with_id
            final_grade = rows[1]["Final Score"].try(:to_f)
            expect(final_grade).to eq 20
          end

          it "exports assignments without due dates if exporting last grading period" do
            expect(headers).to include @current_assignment.title_with_id,
                                       @no_due_date_assignment.title_with_id
            final_grade = rows[1]["Final Score"].try(:to_f)
            expect(final_grade).to eq 20
          end

          it "does not export assignments without due date" do
            @grading_period_id = first_period.id
            expect(headers).to_not include @no_due_date_assignment.title_with_id
          end

          it "does not export assignments in other grading periods" do
            expect(headers).to_not include @past_assignment.title_with_id,
                                           @future_assignment.title_with_id
          end

          it "does not export future assignments" do
            expect(headers).to_not include @future_assignment.title_with_id
          end

          it "exports the entire gradebook when grading_period_id is 0" do
            @grading_period_id = 0
            expect(headers).to include @past_assignment.title_with_id,
                                       @current_assignment.title_with_id,
                                       @future_assignment.title_with_id,
                                       @no_due_date_assignment.title_with_id
            expect(headers).not_to include "Final Score"
          end
        end
      end


      describe "when multiple grading periods is off" do
        describe "all assignments are exported" do
          let!(:disable_mgp) do
            course.disable_feature!(:multiple_grading_periods)
          end

          it "includes all assignments" do
            expect(headers).to include @no_due_date_assignment.title_with_id,
                                       @current_assignment.title_with_id,
                                       @past_assignment.title_with_id,
                                       @future_assignment.title_with_id
            final_grade = rows[1]["Final Score"].try(:to_f)
            expect(final_grade).to eq 25
          end
        end
      end
    end

    it "should include inactive students" do
      assmt = @course.assignments.create!(title: "assmt", points_possible: 10)

      student1_enrollment = student_in_course(course: @course, active_all: true)
      student1 = student1_enrollment.user
      student2_enrollment = student_in_course(course: @course, active_all: true)
      student2 = student2_enrollment.user

      assmt.grade_student(student1, grade: 1, grader: @teacher)
      assmt.grade_student(student2, grade: 2, grader: @teacher)

      student1_enrollment.deactivate
      student2_enrollment.deactivate

      teacher.preferences[:gradebook_settings] =
      { course.id =>
        {
          'show_inactive_enrollments' => 'true',
          'show_concluded_enrollments' => 'false'
        }
      }
      teacher.save!

      csv = exporter.to_csv
      rows = CSV.parse(csv, headers: true)

      expect([rows[1]["ID"], rows[2]["ID"]]).to match_array([student1.id.to_s, student2.id.to_s])
    end

    it 'handles gracefully any assignments with nil position' do
      course.assignments.create! title: 'assignment #1'
      assignment = course.assignments.create! title: 'assignment #2'
      assignment.update_attribute(:position, nil)

      expect { exporter.to_csv }.not_to raise_error
    end
  end

  context "a course with a student whose name starts with an equals sign" do
    let(:student) do
      user = user(name: "=sum(A)", active_user: true)
      course_with_student(course: course, user: user)
      user
    end
    let(:course) { @course }
    let(:assignment) { course.assignments.create!(title: "Assignment", points_possible: 4) }

    it "quotes the name that starts with an equals so it's not considered a formula" do
      assignment.grade_student(student, grade: 1, grader: @teacher)
      csv = GradebookExporter.new(course, @teacher, {}).to_csv
      rows = CSV.parse(csv, headers: true)

      expect(rows[1][0]).to eql('="=sum(A)"')
    end
  end
end
