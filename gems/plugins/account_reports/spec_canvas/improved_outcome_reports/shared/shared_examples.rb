# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

RSpec.shared_examples "common outcomes report behavior" do
  it "runs the report" do
    expect(report[0].headers).to eq expected_headers
  end

  it "has correct values" do
    verify_all(report, all_values)
  end

  it "includes concluded courses" do
    @course1.update! workflow_state: "completed"
    verify_all(report, all_values)
  end

  context "with a term" do
    before do
      @term1 = @root_account.enrollment_terms.create!(
        name: "Fall",
        start_at: 6.months.ago,
        end_at: 1.year.from_now,
        sis_source_id: "fall12"
      )
    end

    let(:report_params) { { params: { "enrollment_term" => @term1.id } } }

    it "filters out courses not in term" do
      expect(report.length).to eq 1
      expect(report[0][0]).to eq "No outcomes found"
    end

    it "includes courses in term" do
      @course1.update! enrollment_term: @term1
      verify_all(report, all_values)
    end
  end

  context "with a sub account" do
    before(:once) do
      @sub_account = Account.create(parent_account: @root_account, name: "English")
    end

    let(:report_params) { { account: @sub_account } }
    let(:common_values) do
      {
        course: @course1,
        section: @section,
        assignment: @assignment,
        outcome: @outcome,
        outcome_group: @sub_account.root_outcome_group
      }
    end

    it "filters courses in a sub account" do
      expect(report.length).to eq 1
      expect(report[0][0]).to eq "No outcomes found"
    end

    it "includes courses in the sub account" do
      @sub_account.root_outcome_group.add_outcome(@outcome)
      @course1.update! account: @sub_account
      verify_all(report, all_values)
    end
  end

  context "with deleted enrollments" do
    before(:once) do
      @enrollment2.destroy!
    end

    it "excludes deleted enrollments by default" do
      remaining_values = all_values.reject { |v| v[:user] == @user2 }
      verify_all(report, remaining_values)
    end

    it "includes deleted enrollments when include_deleted is set" do
      report_record = run_report(report_type, account: @root_account, params: { "include_deleted" => true })
      expect(report_record.parameters["extra_text"]).to eq "Term: All Terms; Include Deleted/Concluded Objects;"

      report = parse_report(report_record, order:, parse_header: true)
      verify_all(report, all_values)
    end
  end

  it "does not include scores when hidden on learning outcome results" do
    lor = user1_values[:outcome_result]
    lor.update!(hide_points: true)
    verify_all(report, all_values)
  end

  it "does not include invalid learning outcome results" do
    # create result that is invalid because
    # it has an artifact type of submission, instead of
    # a rubric assessment or assessment question
    LearningOutcomeResult.create(
      alignment: ContentTag.create!({
                                      title: "content",
                                      context: @course1,
                                      learning_outcome: @outcopme,
                                      content_id: @assignment.id
                                    }),
      user: @user1,
      artifact: @submission,
      context: @course1,
      possible: @assignment.points_possible,
      score: @submission.score,
      learning_outcome_id: @outcome.id
    )
    verify_all(report, all_values)
  end

  context "with multiple subaccounts" do
    before(:once) do
      @subaccount1 = Account.create! parent_account: @root_account
      @subaccount2 = Account.create! parent_account: @root_account
      @enrollment1 = course_with_student(account: @subaccount1, user: @user1, active_all: true)
      @enrollment2 = course_with_student(account: @subaccount2, user: @user2, active_all: true)
      @rubric1 = outcome_with_rubric(outcome: @outcome, course: @enrollment1.course, outcome_context: @subaccount1)
      @rubric2 = outcome_with_rubric(outcome: @outcome, course: @enrollment2.course, outcome_context: @subaccount2)
      @assessment1 = rubric_assessment_model(context: @enrollment1.course, rubric: @rubric1, user: @user1)
      @assessment2 = rubric_assessment_model(context: @enrollment2.course, rubric: @rubric2, user: @user2)
    end

    let(:user1_subaccount_values) do
      {
        user: @user1,
        course: @enrollment1.course,
        section: @enrollment1.course_section,
        assignment: @assessment1.submission.assignment,
        outcome: @outcome,
        outcome_group: @subaccount1.root_outcome_group,
        outcome_result: LearningOutcomeResult.find_by(artifact: @assessment1),
        submission: @assessment1.submission
      }
    end
    let(:user2_subaccount_values) do
      {
        user: @user2,
        course: @enrollment2.course,
        section: @enrollment2.course_section,
        assignment: @assessment2.submission.assignment,
        outcome: @outcome,
        outcome_group: @subaccount2.root_outcome_group,
        outcome_result: LearningOutcomeResult.find_by(artifact: @assessment2),
        submission: @assessment2.submission
      }
    end

    it "includes results for all subaccounts when run from the root account" do
      values1 = user2_subaccount_values.merge({ outcome_group: @outcome_group })
      values2 = user1_subaccount_values.merge({ outcome_group: @outcome_group })
      combined_values = all_values + [values1, values2]
      combined_values.sort_by! { |v| v[:user].sortable_name }
      verify_all(report, combined_values)
    end

    it "includes only results from subaccount" do
      report = read_report(report_type, account: @subaccount1, parse_header: true)
      verify_all(report, [user1_subaccount_values])
    end
  end

  context "with multiple pseudonyms" do
    it "includes a row for each pseudonym" do
      new_pseudonym = managed_pseudonym(@user1, account: @root_account, sis_user_id: "x_another_id")
      combined_values = all_values + [user1_values.merge(pseudonym: new_pseudonym)]
      combined_values.sort_by! { |v| v[:user].sortable_name }
      verify_all(report, combined_values)
    end
  end

  context "with multiple enrollments" do
    it "includes a single row for enrollments in the same section" do
      multiple_student_enrollment(@user1, @section, course: @course1)
      multiple_student_enrollment(@user1, @section, course: @course1)
      verify_all(report, all_values)
    end

    it "includes multiple rows for enrollments in different sections" do
      section2 = add_section("double your fun", course: @course1)
      multiple_student_enrollment(@user1, section2, course: @course1)
      combined_values = all_values + [user1_values.merge(section: section2)]
      combined_values.sort_by! { |v| [v[:user].sortable_name, v[:section].id] }
      verify_all(report, combined_values)
    end
  end

  context "with mastery and ratings" do
    let(:user1_rubric_score) { 3 }

    it "includes correct mastery and ratings for different scores" do
      user1_row = report.find { |row| row["student name"] == @user1.sortable_name }
      expect(user1_row["learning outcome rating"]).to eq "Rockin"
      expect(user1_row["learning outcome rating points"]).to eq "3.0"
    end
  end
end
