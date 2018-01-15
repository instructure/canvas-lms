#
# Copyright (C) 2015 - present Instructure, Inc.
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
  before(:each) do
    teacher_in_course active_all: true
    @course.grading_standard_id = 0
    @course.save
  end

  describe "#to_csv" do
    def exporter(opts = {})
      GradebookExporter.new(@course, @teacher, opts)
    end

    describe "default output with blank course" do
      subject(:csv)   { exporter.to_csv }

      it "produces a String" do
        expect(subject).to be_a String
      end

      it "is a csv with two rows" do
        expect(CSV.parse(subject).count).to be 2
      end

      it "has headers in a default order" do
        expected_headers = [
          "\xEF\xBB\xBFStudent", "ID", "SIS Login ID", "Section", "Current Points", "Final Points",
          "Current Score", "Unposted Current Score", "Final Score", "Unposted Final Score",
          "Current Grade", "Unposted Current Grade", "Final Grade", "Unposted Final Grade"
        ]
        actual_headers = CSV.parse(subject, headers: true).headers

        expect(actual_headers).to match_array(expected_headers)
      end
    end

    context "internationalization" do
      it "can use localized column separators" do
        csv = exporter(col_sep: ";", encoding: "UTF-8").to_csv
        headers = CSV.parse(csv, col_sep: ";", headers: true).headers
        expect(headers[0]).to eq "\xEF\xBB\xBFStudent"
        expect(headers[1]).to eq "ID"
        expect(headers[2]).to eq "SIS Login ID"
      end

      it "can automatically determine the column separator to use" do
        @course.assignments.create!(title: "Verkefni 1", points_possible: 8.5)
        csv = exporter(locale: :is).to_csv
        expect(csv).to match(/;8,5;/)
      end

      it "prepends byte order marker with UTF-8 encoding" do
        csv = exporter(encoding: "UTF-8").to_csv
        headers = CSV.parse(csv, headers: true).headers
        expect(headers[0]).to eq "\xEF\xBB\xBFStudent"
      end

      it "omits byte order marker with US-ASCII encoding" do
        csv = exporter(encoding: "US-ASCII").to_csv
        headers = CSV.parse(csv, headers: true).headers
        expect(headers[0]).to eq "Student".encode("US-ASCII")
      end

      describe "grades" do
        before :each do
          @assignment = @course.assignments.create!(title: 'Verkefni 1', points_possible: 10, grading_type: 'gpa_scale')
          student = student_in_course(course: @course, active_all: true).user
          @assignment.grade_student(student, grader: @teacher, score: 7.5)
          csv = exporter(locale: :is).to_csv
          @icsv = CSV.parse(csv, col_sep: ";", headers: true)
        end

        it "localizes numbers" do
          expect(@icsv[1]['Assignments Current Points']).to eq('7,5')
        end

        it "does not localize grading scheme grades for assignments" do
          expect(@icsv[1]["#{@assignment.title} (#{@assignment.id})"]).to eq('C')
        end

        it "does not localize grading scheme grades for the total" do
          expect(@icsv[1]["Final Grade"]).to eq('C')
        end
      end
    end

    context "a course has assignments with due dates" do
      before(:each) do
        @no_due_date_assignment = @course.assignments.create! title: "no due date",
          points_possible: 10

        @past_assignment = @course.assignments.create! due_at: 5.weeks.ago,
          title: "past",
          points_possible: 10

        @current_assignment = @course.assignments.create! due_at: 1.weeks.from_now,
          title: "current",
          points_possible: 10

        @future_assignment = @course.assignments.create! due_at: 8.weeks.from_now,
          title: "future",
          points_possible: 10

        student_in_course active_all: true

        @no_due_date_assignment.grade_student @student, grade: 1, grader: @teacher
        @past_assignment.grade_student @student, grade: 2, grader: @teacher
        @current_assignment.grade_student @student, grade: 3, grader: @teacher
        @future_assignment.grade_student @student, grade: 4, grader: @teacher

        @group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)

        @first_period = @group.grading_periods.create!(
          start_date: 6.weeks.ago, end_date: 3.weeks.ago, title: "past grading period"
        )
        @last_period = @group.grading_periods.create!(
          start_date: 3.weeks.ago, end_date: 3.weeks.from_now, title: "present day, present time"
        )
      end

      describe "with grading periods" do
        describe "assignments in the selected grading period are exported" do
          before(:each) do
            @csv = exporter(grading_period_id: @last_period.id).to_csv
            @rows = CSV.parse(@csv, headers: true)
            @headers = @rows.headers
          end

          it "exports selected grading period's assignments" do
            expect(@headers).to include @no_due_date_assignment.title_with_id,
                                       @current_assignment.title_with_id
            final_grade = @rows[1]["Final Score"].try(:to_f)
            expect(final_grade).to eq 20
          end

          it "exports assignments without due dates if exporting last grading period" do
            expect(@headers).to include @current_assignment.title_with_id,
                                       @no_due_date_assignment.title_with_id
            final_grade = @rows[1]["Final Score"].try(:to_f)
            expect(final_grade).to eq 20
          end

          it "does not export assignments without due date" do
            @grading_period_id = @first_period.id
            @csv = exporter(grading_period_id: @grading_period_id).to_csv
            @rows = CSV.parse(@csv, headers: true)
            @headers = @rows.headers

            expect(@headers).to_not include @no_due_date_assignment.title_with_id
          end

          it "does not export assignments in other grading periods" do
            expect(@headers).to_not include @past_assignment.title_with_id,
                                           @future_assignment.title_with_id
          end

          it "does not export future assignments" do
            expect(@headers).to_not include @future_assignment.title_with_id
          end

          it "exports the entire gradebook when grading_period_id is 0" do
            @grading_period_id = 0
            @csv = exporter(grading_period_id: @grading_period_id).to_csv
            @rows = CSV.parse(@csv, headers: true)
            @headers = @rows.headers

            expect(@headers).to include @past_assignment.title_with_id,
                                       @current_assignment.title_with_id,
                                       @future_assignment.title_with_id,
                                       @no_due_date_assignment.title_with_id
            expect(@headers).not_to include "Final Score"
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

      @teacher.preferences[:gradebook_settings] =
      { @course.id =>
        {
          'show_inactive_enrollments' => 'true',
          'show_concluded_enrollments' => 'false'
        }
      }
      @teacher.save!

      csv = exporter.to_csv
      rows = CSV.parse(csv, headers: true)

      expect([rows[1]["ID"], rows[2]["ID"]]).to match_array([student1.id.to_s, student2.id.to_s])
    end

    it 'handles gracefully any assignments with nil position' do
      @course.assignments.create! title: 'assignment #1'
      assignment = @course.assignments.create! title: 'assignment #2'
      assignment.update_attribute(:position, nil)

      expect { exporter.to_csv }.not_to raise_error
    end
  end

  context "a course with a student whose name starts with an equals sign" do
    let(:student) do
      user = user_factory(name: "=sum(A)", active_user: true)
      course_with_student(course: @course, user: user)
      user
    end
    let(:course) { @course }
    let(:assignment) { @course.assignments.create!(title: "Assignment", points_possible: 4) }

    it "quotes the name that starts with an equals so it's not considered a formula" do
      assignment.grade_student(student, grade: 1, grader: @teacher)
      csv = GradebookExporter.new(@course, @teacher, {}).to_csv
      rows = CSV.parse(csv, headers: true)

      expect(rows[1][0]).to eql('="=sum(A)"')
    end
  end

  context "when a course has unposted assignments" do
    let(:posted_assignment) { @course.assignments.create!(title: "Posted", points_possible: 10) }
    let(:unposted_assignment) { @course.assignments.create!(title: "Unposted", points_possible: 10, muted: true) }

    before(:each) do
      @course.assignments.create!(title: "Ungraded", points_possible: 10)

      student_in_course active_all: true

      posted_assignment.grade_student @student, grade: 9, grader: @teacher
      unposted_assignment.grade_student @student, grade: 3, grader: @teacher
    end

    it "calculates assignment group scores correctly" do
      csv = GradebookExporter.new(@course, @teacher, {}).to_csv
      rows = CSV.parse(csv, headers: true)

      expect(rows[2]["Assignments Current Score"].try(:to_f)).to eq 90
      expect(rows[2]["Assignments Unposted Current Score"].try(:to_f)).to eq 60
      expect(rows[2]["Assignments Final Score"].try(:to_f)).to eq 30
      expect(rows[2]["Assignments Unposted Final Score"].try(:to_f)).to eq 40
    end

    it "calculates totals correctly" do
      csv = GradebookExporter.new(@course, @teacher, {}).to_csv
      rows = CSV.parse(csv, headers: true)

      expect(rows[2]["Current Score"].try(:to_f)).to eq 90
      expect(rows[2]["Unposted Current Score"].try(:to_f)).to eq 60
      expect(rows[2]["Final Score"].try(:to_f)).to eq 30
      expect(rows[2]["Unposted Final Score"].try(:to_f)).to eq 40
    end
  end

  describe "#show_overall_totals" do
    before(:each) do
      course_with_teacher
      student_in_course(course: @course, active_all: true)
    end

    context "when a grading period is supplied" do
      it "fetches scores from the Enrollment object using the grading period ID" do
        @group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
        grading_period = @group.grading_periods.create!(
          start_date: 1.week.ago, end_date: 1.week.from_now, title: "test period"
        )

        expect_any_instance_of(StudentEnrollment).to receive(:computed_current_score)
          .with({ grading_period_id: grading_period.id })

        GradebookExporter.new(@course, @teacher, { grading_period_id: grading_period.id }).to_csv
      end
    end

    context "when no grading period is supplied" do
      it "fetches scores from the Enrollment object using the default Course parameters" do
        expect_any_instance_of(StudentEnrollment).to receive(:computed_current_score).with(Score.params_for_course)
        GradebookExporter.new(@course, @teacher, {}).to_csv
      end
    end
  end
end
