# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateGradebookGroupFilter do
  def mutation_str(course_id: nil, assignment_id: nil, anonymous_id: nil)
    anonymous_id_param = anonymous_id.nil? ? "null" : anonymous_id
    <<~GQL
      mutation {
        updateGradebookGroupFilter(input: {courseId: #{course_id}, assignmentId: #{assignment_id}, anonymousId: "#{anonymous_id_param}"}) {
          groupName
          reasonForChange
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create,
        domain_root_account: @course.account.root_account
      }
    )
    result.to_h.with_indifferent_access
  end

  before(:once) do
    @account = Account.create!
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @group_category = @course.group_categories.create!(name: "Category1")
    @group_category.create_groups(3)
    @student1 = @course.enroll_student(User.create!, enrollment_state: "active").user
    @student2 = @course.enroll_student(User.create!, enrollment_state: "active").user
    @student3 = @course.enroll_student(User.create!, enrollment_state: "active").user
    @group_category.groups.first.add_user(@student1)
    @group_category.groups.second.add_user(@student2)
    @group_category.groups.third.add_user(@student3)
    @assignment = @course.assignments.create!
    @student1_submission = @assignment.submit_homework(@student1, body: "test submission")
    @student2_submission = @assignment.submit_homework(@student2, body: "test submission")
    @student3_submission = @assignment.submit_homework(@student3, body: "test submission")
  end

  context "when anonymous id is present" do
    context "when student is in a different group than the currently selected one" do
      it "sets the filter to the group the student is in" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [@group_category.groups.first.id.to_s] } })
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id, anonymous_id: @student2_submission.anonymous_id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to eq @group_category.groups.second.name
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to eq "student_not_in_selected_group"
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq [@group_category.groups.second.id.to_s]
      end

      it "clears all existing group id filters when multiple groups are selected" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [@group_category.groups.first.id.to_s, @group_category.groups.second.id.to_s] } })
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id, anonymous_id: @student3_submission.anonymous_id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to eq @group_category.groups.third.name
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to eq "student_not_in_selected_group"
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq [@group_category.groups.third.id.to_s]
      end
    end

    context "when student is in the same group as the currently selected one" do
      it "does not change the filter" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [@group_category.groups.first.id.to_s] } })
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id, anonymous_id: @student1_submission.anonymous_id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to eq @group_category.groups.first.name
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to be_nil
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq [@group_category.groups.first.id.to_s]
      end

      it "does not change the filter when multiple groups are selected and goes based off of the last or most recently selected filter" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [@group_category.groups.first.id.to_s, @group_category.groups.second.id.to_s, @group_category.groups.last.id.to_s] } })
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id, anonymous_id: @student3_submission.anonymous_id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to eq @group_category.groups.third.name
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to be_nil
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq [@group_category.groups.first.id.to_s, @group_category.groups.second.id.to_s, @group_category.groups.third.id.to_s]
      end
    end

    context "when no group is selected" do
      it "sets the filter to the group the student is in" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [] } })
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id, anonymous_id: @student2_submission.anonymous_id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to eq @group_category.groups.second.name
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to eq "no_group_selected"
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq [@group_category.groups.second.id.to_s]
      end
    end

    context "when student is not in any group" do
      it "clears the filter" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [@group_category.groups.first.id.to_s] } })
        new_student = @course.enroll_student(User.create!, enrollment_state: "active").user
        new_student_submission = @assignment.submit_homework(new_student, body: "test submission")
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id, anonymous_id: new_student_submission.anonymous_id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to be_nil
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to eq "student_in_no_groups"
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq []
      end
    end
  end

  context "when student id is not present" do
    context "when no group is selected" do
      it "sets the filter to the first group with students" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [] } })
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to eq @group_category.groups.first.name
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to eq "no_group_selected"
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq [@group_category.groups.first.id.to_s]
      end
    end

    context "when a group is selected" do
      it "does not change the filter" do
        @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_ids" => [@group_category.groups.first.id.to_s] } })
        result = run_mutation({ course_id: @course.id, assignment_id: @assignment.id })
        expect(result.dig("data", "updateGradebookGroupFilter", "groupName")).to eq @group_category.groups.first.name
        expect(result.dig("data", "updateGradebookGroupFilter", "reasonForChange")).to be_nil
        @teacher.reload
        expect(@teacher.get_preference(:gradebook_settings, @course.global_id)["filter_rows_by"]["student_group_ids"]).to eq [@group_category.groups.first.id.to_s]
      end
    end
  end
end
