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
  before(:once) do
    @course = course_model(grading_standard_id: 0)
    course_with_teacher(course: @course, active_all: true)
  end

  describe "#to_csv" do
    def exporter(opts = {})
      GradebookExporter.new(@course, @teacher, opts)
    end

    describe "custom columns" do
      before(:once) do
        first_column = @course.custom_gradebook_columns.create! title: "Custom Column 1"
        second_column = @course.custom_gradebook_columns.create! title: "Custom Column 2"
        third_column = @course.custom_gradebook_columns.create!({title: "Custom Column 3", workflow_state: "hidden"})

        student1_enrollment = student_in_course(course: @course, active_all: true).user
        student2_enrollment = student_in_course(course: @course, active_all: true).user

        first_column.custom_gradebook_column_data.create!({content: 'Row1 Custom Column 1', user_id: student1_enrollment.id})
        first_column.custom_gradebook_column_data.create!({content: 'Row2 Custom Column 1', user_id: student2_enrollment.id})
        second_column.custom_gradebook_column_data.create!({content: 'Row1 Custom Column 2', user_id: student1_enrollment.id})
        second_column.custom_gradebook_column_data.create!({content: 'Row2 Custom Column 2', user_id: student2_enrollment.id})
        third_column.custom_gradebook_column_data.create!({content: 'Row1 Custom Column 3', user_id: student1_enrollment.id})
        third_column.custom_gradebook_column_data.create!({content: 'Row2 Custom Column 3', user_id: student2_enrollment.id})
      end

      it "have the correct custom column data in proper order" do
        csv = GradebookExporter.new(@course, @teacher).to_csv
        rows = CSV.parse(csv, headers: true)

        expect(rows[1]['Custom Column 1']).to eq 'Row1 Custom Column 1'
        expect(rows[2]['Custom Column 1']).to eq 'Row2 Custom Column 1'
        expect(rows[1]['Custom Column 2']).to eq 'Row1 Custom Column 2'
        expect(rows[2]['Custom Column 2']).to eq 'Row2 Custom Column 2'
        expect(rows[1]['Custom Column 3']).to eq nil
        expect(rows[2]['Custom Column 3']).to eq nil
      end
    end

    describe "default output with blank course" do
      before(:once) do
        @course.custom_gradebook_columns.create! title: "Custom Column 1"
        @course.custom_gradebook_columns.create! title: "Custom Column 2"
        @course.custom_gradebook_columns.create!({title: "Custom Column 3", workflow_state: "hidden"})
      end

      subject(:csv) { exporter.to_csv }

      it { is_expected.to be_a String }

      it "is a csv with two rows" do
        expect(CSV.parse(csv).count).to be 2
      end

      it "is a csv with rows of equal length" do
        rows = CSV.parse(csv)
        expect(rows.first.length).to eq rows.second.length
      end

      it "has headers in a default order" do
        expected_headers = [
          "Student", "ID", "SIS Login ID", "Section", "Custom Column 1", "Custom Column 2",
          "Current Points", "Final Points",
          "Current Score", "Unposted Current Score", "Final Score", "Unposted Final Score",
          "Current Grade", "Unposted Current Grade", "Final Grade", "Unposted Final Grade"
        ]

        actual_headers = CSV.parse(csv, headers: true).headers

        expect(actual_headers).to match_array(expected_headers)
      end

      describe "byte-order mark" do
        it "is included when the user has it enabled" do
          @teacher.enable_feature!(:include_byte_order_mark_in_gradebook_exports)
          actual_headers = CSV.parse(exporter.to_csv, headers: true).headers
          expect(actual_headers[0]).to eq("\xEF\xBB\xBFStudent")
        end

        it "is excluded when the user has it disabled" do
          @teacher.disable_feature!(:include_byte_order_mark_in_gradebook_exports)
          actual_headers = CSV.parse(exporter.to_csv, headers: true).headers
          expect(actual_headers[0]).to eq("Student")
        end
      end

      context "when muted assignments are present" do
        before(:each) do
          @course.assignments.create!(muted: true, points_possible: 10)
          @exporter_options = {}
        end

        let(:csv) do
          unparsed_csv = GradebookExporter.new(@course, @teacher, @exporter_options).to_csv
          CSV.parse(unparsed_csv)
        end

        let(:header_row_length) { csv.first.length }
        let(:muted_row_length) { csv.second.length }

        it "the length of the 'muted' row matches the length of the header row" do
          expect(header_row_length).to eq muted_row_length
        end

        it "the length of the 'muted' row matches the length of the header row when include_sis_id is true" do
          @exporter_options[:include_sis_id] = true
          expect(header_row_length).to eq muted_row_length
        end

        it "the length of the 'muted' row matches the length of the header row when include_sis_id " \
          "is true and the account is a trust account" do
          expect(@course.root_account).to receive(:trust_exists?).and_return(true)
          @exporter_options[:include_sis_id] = true
          expect(header_row_length).to eq muted_row_length
        end
      end
    end

    context "internationalization" do
      it "can use localized column separators" do
        csv = exporter(col_sep: ";", encoding: "UTF-8").to_csv
        actual_headers = CSV.parse(csv, col_sep: ";", headers: true).headers
        expected_headers = ['Student', 'ID', 'SIS Login ID']

        expect(actual_headers[0..2]).to eq(expected_headers)
      end

      it "can automatically determine the column separator to use when asked to autodetect" do
        @teacher.enable_feature!(:autodetect_field_separators_for_gradebook_exports)
        @course.assignments.create!(title: "Verkefni 1", points_possible: 8.5)
        csv = exporter(locale: :is).to_csv
        expect(csv).to match(/;8,5;/)
      end

      it "uses comma as the column separator when not asked to autodetect" do
        @course.assignments.create!(title: "Verkefni 1", points_possible: 8.5)
        csv = exporter(locale: :is).to_csv
        expect(csv).to match(/,"8,5",/)
      end

      it "prepends byte order mark with UTF-8 encoding when the user enables it" do
        @teacher.enable_feature!(:include_byte_order_mark_in_gradebook_exports)
        csv = exporter(encoding: "UTF-8").to_csv
        headers = CSV.parse(csv, headers: true).headers
        expect(headers[0]).to eq "\xEF\xBB\xBFStudent"
      end

      it "omits byte order mark with US-ASCII encoding even when the user enables it" do
        @teacher.enable_feature!(:include_byte_order_mark_in_gradebook_exports)
        csv = exporter(encoding: "US-ASCII").to_csv
        headers = CSV.parse(csv, headers: true).headers
        expect(headers[0]).to eq "Student".encode("US-ASCII")
      end

      describe "grades" do
        before :each do
          @assignment = @course.assignments.create!(title: 'Verkefni 1', points_possible: 10, grading_type: 'gpa_scale')
          student = student_in_course(course: @course, active_all: true).user
          @assignment.grade_student(student, grader: @teacher, score: 7.5)
        end

        context 'when forcing the field separator to be a semicolon' do
          before :each do
            @teacher.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
            @csv = exporter(locale: :is).to_csv
            @icsv = CSV.parse(@csv, col_sep: ";", headers: true)
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

        context 'when not forcing the field separator to be a semicolon' do
          before :each do
            @teacher.disable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
          end

          context 'when autodetecting field separator to use' do
            before :each do
              @teacher.enable_feature!(:autodetect_field_separators_for_gradebook_exports)
              @csv = exporter(locale: :is).to_csv
              @icsv = CSV.parse(@csv, col_sep: ";", headers: true)
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

          context 'when not autodetecting field separator to use' do
            before :each do
              @teacher.disable_feature!(:autodetect_field_separators_for_gradebook_exports)
              @csv = exporter(locale: :is).to_csv
              @icsv = CSV.parse(@csv, col_sep: ",", headers: true)
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

  context "with weighted assignment groups" do
    before(:once) do
      student_in_course active_all: true
      @course.update_attributes(group_weighting_scheme: 'percent')

      first_group = @course.assignment_groups.create!(name: "First Group", group_weight: 0.5)
      @course.assignment_groups.create!(name: "Second Group", group_weight: 0.5)

      @assignment = @course.assignments.create!(title: 'Assignment 1', points_possible: 10,
                                                grading_type: 'gpa_scale', assignment_group: first_group)
      @assignment.grade_student(@student, grade: 8, grader: @teacher)
    end

    it "emits rows of equal length when no assignments are muted" do
      csv = GradebookExporter.new(@course, @teacher, {}).to_csv
      rows = CSV.parse(csv)

      expect(rows.group_by(&:size).count).to be 1
    end

    it "emits rows of equal length when an assignment is muted" do
      @assignment.mute!
      csv = GradebookExporter.new(@course, @teacher, {}).to_csv
      rows = CSV.parse(csv)

      expect(rows.group_by(&:size).count).to be 1
    end
  end

  describe "#show_overall_totals" do
    let(:enrollment) { @student.enrollments.find_by(course: @course) }

    before(:once) do
      student_in_course(course: @course, active_all: true)
    end

    # this test is needed to guarantee the stubbing in the following specs on
    # enrollment reflects reality and isn't a false positive.
    it 'includes the student enrollment in the course' do
      exporter = GradebookExporter.new(@course, @teacher)

      expect(exporter).to receive(:enrollments_for_csv).with([enrollment]).and_call_original
      exporter.to_csv
    end

    context "when a grading period is present" do
      let(:group) { Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course) }
      let(:grading_period) do
        group.grading_periods.create!(
          start_date: 1.week.ago, end_date: 1.week.from_now, title: "test period"
        )
      end
      let(:exporter) { GradebookExporter.new(@course, @teacher, { grading_period_id: grading_period.id }) }

      before(:each) do
        allow(exporter).to receive(:enrollments_for_csv).and_return([enrollment])
      end

      it 'includes the computed current score for the grading period' do
        expect(enrollment).to receive(:computed_current_score).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end

      it 'includes the unposted current score for the grading period' do
        expect(enrollment).to receive(:unposted_current_score).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end

      it 'includes the computed final score for the grading period' do
        expect(enrollment).to receive(:computed_final_score).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end

      it 'includes the unposted final score for the grading period' do
        expect(enrollment).to receive(:unposted_final_score).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end

      it 'includes the computed current grade for the grading period' do
        expect(enrollment).to receive(:computed_current_grade).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end

      it 'includes the unposted current grade for the grading period' do
        expect(enrollment).to receive(:unposted_current_grade).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end

      it 'includes the computed final grade for the grading period' do
        expect(enrollment).to receive(:computed_final_grade).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end

      it 'includes the unposted final grade for the grading period' do
        expect(enrollment).to receive(:unposted_final_grade).with({ grading_period_id: grading_period.id })
        exporter.to_csv
      end
    end

    context "when no grading period is supplied" do
      let(:exporter) { GradebookExporter.new(@course, @teacher) }

      before(:each) do
        allow(exporter).to receive(:enrollments_for_csv).and_return([enrollment])
      end

      it 'includes the computed current score for the course' do
        expect(enrollment).to receive(:computed_current_score).with(Score.params_for_course)
        exporter.to_csv
      end

      it 'includes the unposted current score for the course' do
        expect(enrollment).to receive(:unposted_current_score).with(Score.params_for_course)
        exporter.to_csv
      end

      it 'includes the computed final score for the course' do
        expect(enrollment).to receive(:computed_final_score).with(Score.params_for_course)
        exporter.to_csv
      end

      it 'includes the unposted final score for the course' do
        expect(enrollment).to receive(:unposted_final_score).with(Score.params_for_course)
        exporter.to_csv
      end

      it 'includes the computed current grade for the course' do
        expect(enrollment).to receive(:computed_current_grade).with(Score.params_for_course)
        exporter.to_csv
      end

      it 'includes the unposted current grade for the course' do
        expect(enrollment).to receive(:unposted_current_grade).with(Score.params_for_course)
        exporter.to_csv
      end

      it 'includes the computed final grade for the course' do
        expect(enrollment).to receive(:computed_final_grade).with(Score.params_for_course)
        exporter.to_csv
      end

      it 'includes the unposted final grade for the course' do
        expect(enrollment).to receive(:unposted_final_grade).with(Score.params_for_course)
        exporter.to_csv
      end
    end
  end
end
