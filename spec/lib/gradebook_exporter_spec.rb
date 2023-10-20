# frozen_string_literal: true

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

require_relative "../spec_helper"

describe GradebookExporter do
  before(:once) do
    @course = course_model(grading_standard_id: 0)
    course_with_teacher(course: @course, active_all: true)
  end

  def enable_final_grade_override!
    @course.enable_feature!(:final_grades_override)
    @course.update!(allow_final_grade_override: true)
  end

  describe "#to_csv" do
    def exporter(opts = {})
      GradebookExporter.new(@course, @teacher, opts)
    end

    describe "assignment order" do
      def format_assignment_preferences(assignments)
        assignments.map { |assignment| "assignment_#{assignment.id}" }
      end

      def format_assignment_headers(assignments)
        assignments.map(&:title_with_id)
      end

      before(:once) do
        student_in_course(course: @course, active_all: true)

        # The assignment groups are created out of order on purpose. The old code would order by assignment_group.id, so
        # by creating the assignment groups out of order, we should get ids that are out of order. The new code orders
        # using assignment_group.position which is guaranteed to be there in the model.
        @first_group = @course.assignment_groups.create!(name: "first group", position: 1)
        @last_group = @course.assignment_groups.create!(name: "last group", position: 3)
        @second_group = @course.assignment_groups.create!(name: "second group", position: 2)

        @assignments = []
        @first_group_assignment = @course.assignments.create!(name: "First group assignment", assignment_group: @first_group)
        @assignments[0] = @first_group_assignment
        @last_group_assignment = @course.assignments.create!(name: "last group assignment", assignment_group: @last_group)
        @assignments[2] = @last_group_assignment
        @second_group_assignment = @course.assignments.create!(name: "second group assignment", assignment_group: @second_group)
        @assignments[1] = @second_group_assignment
        @exporter_options = {}
      end

      let(:headers) do
        csv = GradebookExporter.new(@course, @teacher, @exporter_options).to_csv
        CSV.parse(csv, headers: true).headers
      end

      context "when assignment column order is specified" do
        it "returns assignments ordered by the supplied custom order" do
          custom_assignment_order = [@last_group_assignment, @second_group_assignment, @first_group_assignment]
          @exporter_options[:assignment_order] = custom_assignment_order.map(&:id)
          actual_assignment_headers = headers[4, 3]

          expect(actual_assignment_headers).to eq format_assignment_headers(custom_assignment_order)
        end

        it "orders assignments not in the custom order after the assignments in the custom order" do
          custom_assignment_order = [@second_group_assignment, @first_group_assignment]
          @exporter_options[:assignment_order] = custom_assignment_order.map(&:id)

          actual_assignment_headers = headers[4, 3]
          expected_assignment_headers = format_assignment_headers [@second_group_assignment, @first_group_assignment, @last_group_assignment]

          expect(actual_assignment_headers).to eq expected_assignment_headers
        end

        it "orders by ID within the group of assignments not in the custom order" do
          custom_assignment_order = [@last_group_assignment]
          @exporter_options[:assignment_order] = custom_assignment_order.map(&:id)

          actual_assignment_headers = headers[4, 3]
          expected_assignment_headers = format_assignment_headers [@last_group_assignment, @first_group_assignment, @second_group_assignment]

          expect(actual_assignment_headers).to eq expected_assignment_headers
        end

        it "includes a column for anonymized assignments" do
          @first_group_assignment.update!(anonymous_grading: true)

          expect(headers).to include(/First group assignment/)
        end
      end

      context "when assignment column order preferences do not exist" do
        it "returns assignments ordered by assignment group position" do
          actual_assignment_headers = headers[4, 3]
          expected_headers = format_assignment_headers @assignments

          expect(actual_assignment_headers).to eq(expected_headers)
        end

        it "includes a column for anonymized assignments" do
          @first_group_assignment.update!(anonymous_grading: true)

          expect(headers).to include(/First group assignment/)
        end
      end
    end

    describe "custom columns" do
      before(:once) do
        first_column = @course.custom_gradebook_columns.create! title: "Custom Column 1"
        second_column = @course.custom_gradebook_columns.create! title: "Custom Column 2"
        third_column = @course.custom_gradebook_columns.create!({ title: "Custom Column 3", workflow_state: "hidden" })

        student1_enrollment = student_in_course(course: @course, active_all: true).user
        student2_enrollment = student_in_course(course: @course, active_all: true).user

        first_column.custom_gradebook_column_data.create!({ content: "Row1 Custom Column 1", user_id: student1_enrollment.id })
        first_column.custom_gradebook_column_data.create!({ content: "Row2 Custom Column 1", user_id: student2_enrollment.id })
        second_column.custom_gradebook_column_data.create!({ content: "Row1 Custom Column 2", user_id: student1_enrollment.id })
        second_column.custom_gradebook_column_data.create!({ content: "Row2 Custom Column 2", user_id: student2_enrollment.id })
        third_column.custom_gradebook_column_data.create!({ content: "Row1 Custom Column 3", user_id: student1_enrollment.id })
        third_column.custom_gradebook_column_data.create!({ content: "Row2 Custom Column 3", user_id: student2_enrollment.id })
      end

      it "have the correct custom column data in proper order" do
        csv = GradebookExporter.new(@course, @teacher).to_csv
        rows = CSV.parse(csv, headers: true)

        expect(rows[1]["Custom Column 1"]).to eq "Row1 Custom Column 1"
        expect(rows[2]["Custom Column 1"]).to eq "Row2 Custom Column 1"
        expect(rows[1]["Custom Column 2"]).to eq "Row1 Custom Column 2"
        expect(rows[2]["Custom Column 2"]).to eq "Row2 Custom Column 2"
        expect(rows[1]["Custom Column 3"]).to be_nil
        expect(rows[2]["Custom Column 3"]).to be_nil
      end
    end

    describe "separate columns for student last and first names" do
      subject(:csv) { exporter(@exporter_options).to_csv }

      before(:once) do
        @exporter_options = {}
        @current_assignment = @course.assignments.create! due_at: 1.week.from_now,
                                                          title: "current",
                                                          points_possible: 10
        student_in_course active_all: true
        @current_assignment.grade_student @student, grade: 3, grader: @teacher
        @rows = CSV.parse(csv)
      end

      it "is a csv with three rows" do
        expect(@rows.count).to be 3
      end

      it "is a csv with rows of equal length" do
        expect(@rows.first.length).to eq @rows.second.length
      end

      it "shows student first and last names in headers" do
        @exporter_options[:show_student_first_last_name] = true
        expect(CSV.parse(csv, headers: true).headers).to include("LastName", "FirstName")
        expect(CSV.parse(csv, headers: true).headers).not_to include("Student")
      end

      it "shows student first and last name in rows" do
        @exporter_options[:show_student_first_last_name] = true
        rows = CSV.parse(csv)
        expect(rows[2][0]).to eq(@student.last_name)
        expect(rows[2][1]).to eq(@student.first_name)
      end
    end

    describe "default output with blank course" do
      subject(:csv) { exporter.to_csv }

      before(:once) do
        @course.custom_gradebook_columns.create! title: "Custom Column 1"
        @course.custom_gradebook_columns.create! title: "Custom Column 2"
        @course.custom_gradebook_columns.create!({ title: "Custom Column 3", workflow_state: "hidden" })
      end

      let(:expected_headers) do
        [
          "Student",
          "ID",
          "SIS Login ID",
          "Section",
          "Custom Column 1",
          "Custom Column 2",
          "Current Points",
          "Final Points",
          "Current Score",
          "Unposted Current Score",
          "Final Score",
          "Unposted Final Score",
          "Current Grade",
          "Unposted Current Grade",
          "Final Grade",
          "Unposted Final Grade"
        ]
      end

      it { is_expected.to be_a String }

      it "is a csv with two rows" do
        expect(CSV.parse(csv).count).to be 2
      end

      it "is a csv with rows of equal length" do
        rows = CSV.parse(csv)
        expect(rows.first.length).to eq rows.second.length
      end

      it "has headers in a default order" do
        actual_headers = CSV.parse(csv, headers: true).headers
        expect(actual_headers).to match_array(expected_headers)
      end

      context "when Final Grade Override is enabled" do
        before(:once) { enable_final_grade_override! }

        let_once(:override_headers) { expected_headers.push("Override Score") }

        it "includes Override Status" do
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).to include "Override Status"
        end

        it "does not include Override Status when 'Custom Status Labels' is disabled" do
          Account.site_admin.disable_feature!(:custom_gradebook_statuses)
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).not_to include "Override Status"
        end

        it "includes the Override Score when the course has a grading standard" do
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).to include "Override Score"
        end

        it "includes the Override Grade headers when the course has a grading standard" do
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).to include "Override Grade"
        end

        it "omits the Override Grade header when the course lacks a grading standard" do
          @course.update!(grading_standard_id: nil)
          actual_headers = CSV.parse(exporter.to_csv, headers: true).headers
          expect(actual_headers).not_to include("Override Grade")
        end
      end

      context "when Final Grade Override is not enabled on the course" do
        before(:once) do
          @course.enable_feature!(:final_grades_override)
          @course.update!(allow_final_grade_override: false)
        end

        it "excludes the Override Score headers" do
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).not_to include("Override Grade")
        end

        it "excludes the Override Grade headers when the course has a grading standard" do
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).not_to include("Override Score")
        end
      end

      context "when Final Grade Override is not enabled as a feature" do
        it "excludes the Override Score headers" do
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).not_to include("Override Grade")
        end

        it "excludes the Override Grade headers when the course has a grading standard" do
          actual_headers = CSV.parse(csv, headers: true).headers
          expect(actual_headers).not_to include("Override Score")
        end
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
        before do
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

        it "the length of the 'muted' row matches the length of the header row when integration_ids are passed" do
          @exporter_options[:include_sis_id] = true
          @course.root_account.settings[:include_integration_ids_in_gradebook_exports] = true
          @course.root_account.save!
          expect(header_row_length).to eq muted_row_length
        end

        it "the length of the 'muted' row matches the length of the header row when include_sis_id " \
           "is true and the account is a trust account" do
          expect(@course.root_account).to receive(:trust_exists?).and_return(true)
          @exporter_options[:include_sis_id] = true
          expect(header_row_length).to eq muted_row_length
        end
      end

      context "when at least one assignment is manually-posted" do
        let_once(:manual_assignment) { @course.assignments.create!(title: "manual") }
        let_once(:manual_header) { "manual (#{manual_assignment.id})" }
        let_once(:auto_assignment) { @course.assignments.create!(title: "auto") }
        let_once(:auto_header) { "auto (#{auto_assignment.id})" }

        let(:csv) do
          unparsed_csv = GradebookExporter.new(@course, @teacher, {}).to_csv
          CSV.parse(unparsed_csv, headers: true)
        end

        before(:once) do
          manual_assignment.ensure_post_policy(post_manually: true)
          auto_assignment.ensure_post_policy(post_manually: false)
        end

        let(:manual_posting_row) { csv[0] }

        it "includes a line consisting entirely of 'Manual Posting' or empty values" do
          expect(manual_posting_row.fields.uniq).to contain_exactly(nil, "Manual Posting")
        end

        it "designates manually-posted assignments as 'Manual Posting'" do
          expect(manual_posting_row[manual_header]).to eq "Manual Posting"
        end

        it "has a special designation for anonymous unposted assignments" do
          course_with_student(course: @course, active_all: true)
          manual_assignment.update!(anonymous_grading: true)
          expect(manual_posting_row[manual_header]).to eq "Manual Posting (scores hidden from instructors)"
        end

        it "emits an empty value for auto-posted assignments" do
          expect(manual_posting_row[auto_header]).to be_nil
        end
      end

      it "omits the 'Manual Posting' row if no assignments are manually-posted" do
        unparsed_csv = GradebookExporter.new(@course, @teacher, {}).to_csv
        csv = CSV.parse(unparsed_csv, headers: true)

        auto_assignment = @course.assignments.create!(title: "auto")
        auto_assignment.ensure_post_policy(post_manually: false)

        expect(csv[0].fields).not_to include("Manual Posting")
      end
    end

    context "internationalization" do
      it "can use localized column separators" do
        csv = exporter(col_sep: ";", encoding: "UTF-8").to_csv
        actual_headers = CSV.parse(csv, col_sep: ";", headers: true).headers
        expected_headers = ["Student", "ID", "SIS Login ID"]

        expect(actual_headers[0..2]).to eq(expected_headers)
      end

      it "can automatically determine the column separator to use when asked to autodetect" do
        @teacher.enable_feature!(:autodetect_field_separators_for_gradebook_exports)
        @course.assignments.create!(title: "Verkefni 1", points_possible: 8.5)
        csv = exporter(locale: :is).to_csv
        expect(csv).to match(/;8,50;/)
      end

      it "uses comma as the column separator when not asked to autodetect" do
        @course.assignments.create!(title: "Verkefni 1", points_possible: 8.5)
        csv = exporter(locale: :is).to_csv
        expect(csv).to match(/,"8,50",/)
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
        before do
          @assignment = @course.assignments.create!(title: "Verkefni 1", points_possible: 10, grading_type: "gpa_scale")
          @student = student_in_course(course: @course, active_all: true).user
          @assignment.grade_student(@student, grader: @teacher, score: 7.5)
        end

        context "when forcing the field separator to be a semicolon" do
          before do
            @teacher.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
            @csv = exporter(locale: :is).to_csv
            @icsv = CSV.parse(@csv, col_sep: ";", headers: true)
          end

          it "localizes numbers" do
            expect(@icsv[1]["Assignments Current Points"]).to eq("7,50")
          end

          it "does not localize grading scheme grades for assignments" do
            expect(@icsv[1]["#{@assignment.title} (#{@assignment.id})"]).to eq("C")
          end

          it "does not localize grading scheme grades for the total" do
            expect(@icsv[1]["Final Grade"]).to eq("C")
          end
        end

        context "when not forcing the field separator to be a semicolon" do
          before do
            @teacher.disable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
          end

          context "when autodetecting field separator to use" do
            before do
              @teacher.enable_feature!(:autodetect_field_separators_for_gradebook_exports)
              @csv = exporter(locale: :is).to_csv
              @icsv = CSV.parse(@csv, col_sep: ";", headers: true)
            end

            it "localizes numbers" do
              expect(@icsv[1]["Assignments Current Points"]).to eq("7,50")
            end

            it "does not localize grading scheme grades for assignments" do
              expect(@icsv[1]["#{@assignment.title} (#{@assignment.id})"]).to eq("C")
            end

            it "does not localize grading scheme grades for the total" do
              expect(@icsv[1]["Final Grade"]).to eq("C")
            end
          end

          context "when not autodetecting field separator to use" do
            before do
              @teacher.disable_feature!(:autodetect_field_separators_for_gradebook_exports)
              @csv = exporter(locale: :is).to_csv
              @icsv = CSV.parse(@csv, col_sep: ",", headers: true)
            end

            it "localizes numbers" do
              expect(@icsv[1]["Assignments Current Points"]).to eq("7,50")
            end

            it "does not localize grading scheme grades for assignments" do
              expect(@icsv[1]["#{@assignment.title} (#{@assignment.id})"]).to eq("C")
            end

            it "does not localize grading scheme grades for the total" do
              expect(@icsv[1]["Final Grade"]).to eq("C")
            end
          end
        end

        it "rounds scores to two decimal places" do
          @assignment.update!(grading_type: "points")
          @assignment.grade_student(@student, grader: @teacher, score: 7.555)
          csv = exporter.to_csv
          parsed_csv = CSV.parse(csv, headers: true)

          expect(parsed_csv[1]["#{@assignment.title} (#{@assignment.id})"]).to eq "7.56"
        end
      end
    end

    context "a course has assignments with due dates" do
      before do
        @no_due_date_assignment = @course.assignments.create! title: "no due date",
                                                              points_possible: 10

        @past_assignment = @course.assignments.create! due_at: 5.weeks.ago,
                                                       title: "past",
                                                       points_possible: 10

        @current_assignment = @course.assignments.create! due_at: 1.week.from_now,
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
          describe "export entire gradebook" do
            let(:headers) do
              csv = exporter(grading_period_id: @last_period.id, current_view: false).to_csv
              CSV.parse(csv, headers: true).headers
            end

            it "exports assignments from all grading periods" do
              expect(headers).to include @no_due_date_assignment.title_with_id,
                                         @current_assignment.title_with_id,
                                         @past_assignment.title_with_id,
                                         @future_assignment.title_with_id
            end

            it "does not export totals columns when 'Display Totals for All Grading Periods' disabled" do
              @group.update!(display_totals_for_all_grading_periods: false)
              expect(headers).to_not include "Final Score"
            end

            it "does not throw an error when final grade override is enabled and not exporting totals, and there are hidden assignments" do
              enable_final_grade_override!
              @group.update!(display_totals_for_all_grading_periods: false)
              assignment = @course.assignments.create!
              assignment.ensure_post_policy(post_manually: true)
              expect { headers }.not_to raise_error
            end

            it "exports totals columns when 'Display Totals for All Grading Periods' enabled" do
              @group.update!(display_totals_for_all_grading_periods: true)
              expect(headers).to include "Final Score"
            end
          end

          describe "export current gradebook view" do
            before do
              exporter_options = {
                grading_period_id: @last_period.id,
                current_view: true,
                assignment_order: @course.assignments.pluck(:id),
                student_order: @course.student_enrollments.pluck(:user_id)
              }
              @csv = exporter(exporter_options).to_csv
              @rows = CSV.parse(@csv, headers: true)
              @headers = @rows.headers
            end

            it "exports filtered grading period's assignments with totals columns" do
              expect(@headers).to include @no_due_date_assignment.title_with_id,
                                          @current_assignment.title_with_id
              final_grade = @rows[1]["Final Score (#{@last_period.title})"].try(:to_f)
              expect(final_grade).to eq 20
            end

            it "accepts student_order as an array of numbers" do
              expect(@rows.dig(1, "ID")).to eq @student.id.to_s
            end

            it "accepts student_order as an array of strings" do
              csv = exporter(
                grading_period_id: @last_period.id,
                current_view: true,
                assignment_order: @course.assignments.pluck(:id),
                student_order: @course.student_enrollments.map { |e| e.user_id.to_s }
              ).to_csv
              rows = CSV.parse(csv, headers: true)
              expect(rows.dig(1, "ID")).to eq @student.id.to_s
            end

            it "exports all visible assignments in the gradebook" do
              exporter_options = {
                grading_period_id: @first_period.id,
                current_view: true,
                assignment_order: [@no_due_date_assignment.id, @future_assignment.id],
                student_order: @course.student_enrollments.pluck(:user_id).map(&:to_s)
              }
              @csv = exporter(exporter_options).to_csv
              @rows = CSV.parse(@csv, headers: true)
              @headers = @rows.headers

              expect(@headers).to include @no_due_date_assignment.title_with_id,
                                          @future_assignment.title_with_id

              expect(@headers).to_not include @current_assignment.title_with_id,
                                              @past_assignment.title_with_id
            end
          end
        end
      end
    end

    describe "with inactive students" do
      before :once do
        assmt = @course.assignments.create!(title: "assmt", points_possible: 10)

        student1_enrollment = student_in_course(course: @course, active_all: true)
        @student1 = student1_enrollment.user
        student2_enrollment = student_in_course(course: @course, active_all: true)
        @student2 = student2_enrollment.user

        assmt.grade_student(@student1, grade: 1, grader: @teacher)
        assmt.grade_student(@student2, grade: 2, grader: @teacher)

        student1_enrollment.deactivate
        student2_enrollment.deactivate

        @teacher.set_preference(:gradebook_settings, @course.global_id, {
                                  "show_inactive_enrollments" => "true",
                                  "show_concluded_enrollments" => "false"
                                })
      end

      it "includes inactive students" do
        csv = exporter.to_csv
        rows = CSV.parse(csv, headers: true)
        expect([rows[1]["ID"], rows[2]["ID"]]).to match_array([@student1.id.to_s, @student2.id.to_s])
      end

      it "includes grades for inactive students if show inactive enrollments" do
        csv = exporter.to_csv
        rows = CSV.parse(csv, headers: true)
        assignment_data_first_student = rows[1].find { |column_info| column_info.first.include? "assmt" }
        assignment_data_second_student = rows[2].find { |column_info| column_info.first.include? "assmt" }
        expect([assignment_data_first_student.second, assignment_data_second_student.second]).to match_array(["1.00", "2.00"])
      end

      it "does not include inactive students if show inactive enrollments is set to false" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, {
                                  "show_inactive_enrollments" => "false",
                                  "show_concluded_enrollments" => "false"
                                })
        csv = exporter.to_csv
        rows = CSV.parse(csv, headers: true)
        expect([rows[1], rows[2]]).to match_array([nil, nil])
      end
    end

    it "handles gracefully any assignments with nil position" do
      @course.assignments.create! title: "assignment #1"
      assignment = @course.assignments.create! title: "assignment #2"
      assignment.update_attribute(:position, nil)

      expect { exporter.to_csv }.not_to raise_error
    end

    describe "column headers" do
      before(:once) do
        enable_final_grade_override!

        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.grading_periods.create!(
          start_date: 6.weeks.ago,
          end_date: 3.weeks.ago,
          title: "past grading period"
        )
        @last_grading_period = group.grading_periods.create!(
          start_date: 3.weeks.ago,
          end_date: 3.weeks.from_now,
          title: "present day, present time"
        )

        enrollment_term = @course.root_account.enrollment_terms.create!(grading_period_group: group)
        @course.update!(enrollment_term:)

        assignment_group = @course.assignment_groups.create!(name: "my group")
        @course.assignments.create!(
          assignment_group:,
          due_at: 1.day.after(@last_grading_period.start_date),
          title: "my assignment"
        )
      end

      let(:exporter) do
        exporter_options = {
          grading_period_id: @last_grading_period.id,
          current_view: true,
          assignment_order: @course.assignments.pluck(:id),
          student_order: @course.student_enrollments.pluck(:user_id).map(&:to_s)
        }
        GradebookExporter.new(@course, @teacher, exporter_options)
      end
      let(:exported_headers) { CSV.parse(exporter.to_csv, headers: true).headers }

      let(:total_columns) do
        [
          "Current Points",
          "Final Points",
          "Current Grade",
          "Unposted Current Grade",
          "Final Grade",
          "Unposted Final Grade",
          "Current Score",
          "Unposted Current Score",
          "Final Score",
          "Unposted Final Score"
        ]
      end
      let(:total_and_override_columns) { total_columns + ["Override Score", "Override Grade"] }

      it "appends the grading period to overall total and override columns" do
        columns_with_grading_period = total_and_override_columns.map do |column|
          "#{column} (present day, present time)"
        end

        expect(exported_headers).to include(*columns_with_grading_period)
      end

      it "appends the grading period to assignment group total columns" do
        aggregate_failures do
          expect(exported_headers).to include("my group Current Score (present day, present time)")
          expect(exported_headers).not_to include("my group Current Score")
        end
      end
    end

    describe "update_completion" do
      before(:once) do
        student_in_course(course: @course, active_all: true)
        @first_group = @course.assignment_groups.create!(name: "first group", position: 1)
        @last_group = @course.assignment_groups.create!(name: "last group", position: 3)
        @second_group = @course.assignment_groups.create!(name: "second group", position: 2)

        @assignments = []
        @first_group_assignment = @course.assignments.create!(name: "First group assignment", assignment_group: @first_group)
        @assignments[0] = @first_group_assignment
        @last_group_assignment = @course.assignments.create!(name: "last group assignment", assignment_group: @last_group)
        @assignments[2] = @last_group_assignment
        @second_group_assignment = @course.assignments.create!(name: "second group assignment", assignment_group: @second_group)
        @assignments[1] = @second_group_assignment
      end

      it "updates progress.completion to 90 when finished" do
        progress = Progress.create!(context: @course, tag: "gradebook_to_csv")
        exporter_options = {
          progress:
        }
        GradebookExporter.new(@course, @teacher, exporter_options).to_csv
        expect(progress.reload.completion).to be(90.0)
      end

      it "does early return if progress workflow_state has been set to failed" do
        progress = Progress.create!(context: @course, tag: "gradebook_to_csv")
        progress.update!(workflow_state: "failed")
        exporter_options = {
          progress:
        }
        GradebookExporter.new(@course, @teacher, exporter_options).to_csv
        expect(progress.reload.completion).to be(50.0)
      end
    end
  end

  context "a course with a student whose name starts with an equals sign" do
    let(:student) do
      user = user_factory(name: "=sum(A)", active_user: true)
      course_with_student(course: @course, user:)
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

  context "when a course has anonymous assignments" do
    before do
      @student = User.create!
      student_in_course(user: @student, course: @course, active_all: true)
      @assignment = @course.assignments.create!(title: "Anon Assignment", points_possible: 10, anonymous_grading: true)
      @assignment.ensure_post_policy(post_manually: true)
      @assignment.grade_student(@student, grade: 8, grader: @teacher)
    end

    let(:submission_score) do
      csv = GradebookExporter.new(@course, @teacher, {}).to_csv
      rows = CSV.parse(csv, headers: true)
      rows[2]["Anon Assignment (#{@assignment.id})"]
    end

    it "shows 'N/A' for submission scores in the export when the assignment is unposted" do
      expect(submission_score).to eq "N/A"
    end

    it "shows actual submission scores in the export when the assignment is posted" do
      @assignment.post_submissions
      expect(submission_score).to eq "8.00"
    end
  end

  context "when a course has unposted assignments" do
    let(:posted_assignment) { @course.assignments.create!(title: "Posted", points_possible: 10) }
    let(:unposted_assignment) { @course.assignments.create!(title: "Unposted", points_possible: 10) }
    let(:unposted_anonymous_assignment) do
      @course.assignments.create!(title: "Unposted Anon", points_possible: 10, anonymous_grading: true)
    end

    before do
      @course.assignments.create!(title: "Ungraded", points_possible: 10)

      posted_assignment.ensure_post_policy(post_manually: true)
      unposted_assignment.ensure_post_policy(post_manually: true)
      unposted_anonymous_assignment.ensure_post_policy(post_manually: true)

      student_in_course active_all: true

      posted_assignment.grade_student @student, grade: 9, grader: @teacher
      unposted_assignment.grade_student @student, grade: 3, grader: @teacher
      unposted_anonymous_assignment.grade_student @student, grade: 1, grader: @teacher

      posted_assignment.post_submissions
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
      @course.update(group_weighting_scheme: "percent")

      first_group = @course.assignment_groups.create!(name: "First Group", group_weight: 0.5)
      @course.assignment_groups.create!(name: "Second Group", group_weight: 0.5)

      @assignment = @course.assignments.create!(title: "Assignment 1",
                                                points_possible: 10,
                                                grading_type: "gpa_scale",
                                                assignment_group: first_group)
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
    let(:now) { Time.zone.now }
    let(:enrollment) { @student.enrollments.find_by(course: @course) }
    let(:student_row) { CSV.parse(exporter.to_csv, headers: true)[2] }

    before(:once) do
      student_in_course(course: @course, active_all: true)
      @course.default_post_policy.update!(post_manually: true)

      posted_graded_assignment = @course.assignments.create!(due_at: now, points_possible: 10)
      posted_graded_assignment.grade_student(@student, score: 10, grader: @teacher)
      posted_graded_assignment.post_submissions

      posted_ungraded_assignment = @course.assignments.create!(due_at: now, points_possible: 10)
      posted_ungraded_assignment.post_submissions

      unposted_graded_assignment = @course.assignments.create!(due_at: now, points_possible: 30)
      unposted_graded_assignment.grade_student(@student, score: 24, grader: @teacher)

      @course.assignments.create!(due_at: now, points_possible: 5)
    end

    context "when a grading period is present" do
      let(:group) { Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course) }
      let(:grading_period) do
        group.grading_periods.create!(
          start_date: 1.week.ago(now), end_date: 1.week.from_now(now), title: "test period"
        )
      end
      let(:exporter) do
        exporter_options = {
          grading_period_id: grading_period.id,
          current_view: true,
          assignment_order: @course.assignments.pluck(:id),
          student_order: @course.student_enrollments.pluck(:user_id)
        }
        GradebookExporter.new(@course, @teacher, exporter_options)
      end

      it "includes the scores for the grading period" do
        aggregate_failures do
          expect(student_row["Current Score (#{grading_period.title})"]).to eq "100.00"
          expect(student_row["Unposted Current Score (#{grading_period.title})"]).to eq "85.00"
          expect(student_row["Final Score (#{grading_period.title})"]).to eq "18.18"
          expect(student_row["Unposted Final Score (#{grading_period.title})"]).to eq "61.82"
        end
      end

      it "includes the grades for the grading period" do
        aggregate_failures do
          expect(student_row["Current Grade (#{grading_period.title})"]).to eq "A"
          expect(student_row["Unposted Current Grade (#{grading_period.title})"]).to eq "B"
          expect(student_row["Final Grade (#{grading_period.title})"]).to eq "F"
          expect(student_row["Unposted Final Grade (#{grading_period.title})"]).to eq "D-"
        end
      end

      it "includes the points for the grading period" do
        aggregate_failures do
          expect(student_row["Current Points (#{grading_period.title})"]).to eq "10.00"
          expect(student_row["Final Points (#{grading_period.title})"]).to eq "10.00"
        end
      end

      context "when final grade override is enabled for the course" do
        before do
          enable_final_grade_override!
          custom_grade_status = @course.root_account.custom_grade_statuses.create!(
            name: "Potato",
            color: "#964B00",
            created_by: @teacher
          )
          enrollment.find_score(grading_period:).update!(override_score: 64.0, custom_grade_status:)
        end

        it "includes the overridden score for the current grading period" do
          expect(student_row["Override Score (#{grading_period.title})"]).to eq("64.0")
        end

        it "includes the overridden grade for the current grading period if the course has a grading standard" do
          expect(student_row["Override Grade (#{grading_period.title})"]).to eq("D")
        end

        it "includes the override status for the current grading period" do
          expect(student_row["Override Status (#{grading_period.title})"]).to eq "Potato"
        end

        it "omits the overridden grade for the current grading period if the course has no grading standard" do
          @course.update!(grading_standard_id: nil)
          expect(student_row).not_to have_key "Override Grade (#{grading_period.title})"
        end
      end

      context "when final grade override is not allowed for the course" do
        before do
          @course.enable_feature!(:final_grades_override)
          @course.update!(allow_final_grade_override: false)
          enrollment.find_score(grading_period:).update!(override_score: 64.0)
        end

        it "does not include the overridden score for the current grading period" do
          expect(student_row).not_to have_key "Override Score (#{grading_period.title})"
        end

        it "does not include the overridden grade for the current grading period" do
          expect(student_row).not_to have_key "Override Grade (#{grading_period.title})"
        end
      end

      context "when final grade override is not enabled for the course" do
        it "does not include the overridden score for the current grading period" do
          expect(student_row).not_to have_key "Override Score (#{grading_period.title})"
        end

        it "does not include the overridden grade for the current grading period" do
          expect(student_row).not_to have_key "Override Grade (#{grading_period.title})"
        end
      end
    end

    context "when no grading period is supplied" do
      let(:exporter) { GradebookExporter.new(@course, @teacher) }

      it "includes the scores for the grading period" do
        aggregate_failures do
          expect(student_row["Current Score"]).to eq "100.00"
          expect(student_row["Unposted Current Score"]).to eq "85.00"
          expect(student_row["Final Score"]).to eq "18.18"
          expect(student_row["Unposted Final Score"]).to eq "61.82"
        end
      end

      it "includes the grades for the grading period" do
        aggregate_failures do
          expect(student_row["Current Grade"]).to eq "A"
          expect(student_row["Unposted Current Grade"]).to eq "B"
          expect(student_row["Final Grade"]).to eq "F"
          expect(student_row["Unposted Final Grade"]).to eq "D-"
        end
      end

      context "when final grade override is enabled for the course" do
        before do
          enable_final_grade_override!
          custom_grade_status = @course.root_account.custom_grade_statuses.create!(
            name: "Potato",
            color: "#964B00",
            created_by: @teacher
          )
          enrollment.find_score.update!(override_score: 78.0, custom_grade_status:)
        end

        let(:parsed_csv) { CSV.parse(exporter.to_csv, headers: true) }

        it "includes the overridden score for the course" do
          expect(student_row["Override Score"]).to eq "78.0"
        end

        it "includes the overridden grade for the course" do
          expect(student_row["Override Grade"]).to eq "C+"
        end

        it "omits the overridden grade for the course if the course has no grading standard" do
          @course.update!(grading_standard_id: nil)
          expect(student_row).not_to have_key "Override Grade"
        end

        it "includes the override status for the course" do
          expect(student_row["Override Status"]).to eq "Potato"
        end
      end

      context "when final grade override is not allowed for the course" do
        before do
          @course.enable_feature!(:final_grades_override)
          @course.update!(allow_final_grade_override: false)
        end

        it "does not include the overridden score for the course" do
          expect(student_row).not_to have_key "Override Score"
        end

        it "does not include the overridden grade for the course" do
          expect(student_row).not_to have_key "Override Grade"
        end
      end

      context "when final grade override is not enabled for the course" do
        it "does not include the overridden score for the course" do
          expect(student_row).not_to have_key "Override Score"
        end

        it "does not include the overridden grade for the course" do
          expect(student_row).not_to have_key "Override Grade"
        end
      end
    end
  end
end
