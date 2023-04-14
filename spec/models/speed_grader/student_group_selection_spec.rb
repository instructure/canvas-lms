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

describe SpeedGrader::StudentGroupSelection do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: "some user")

    @course.update!(filter_speed_grader_by_student_group: true)

    category.create_groups(3)
    group1.add_user(group1_student)
    group2.add_user(group2_student)
  end

  let_once(:assignment) { @course.assignments.create! }
  let_once(:category) { @course.group_categories.create!(name: "Category1") }

  let_once(:group1) { category.groups.first }
  let_once(:group2) { category.groups.second }
  let_once(:empty_group) { category.groups.third }

  let_once(:group1_student) { @course.enroll_student(User.create!, enrollment_state: :active).user }
  let_once(:group2_student) { @course.enroll_student(User.create!, enrollment_state: :active).user }
  let_once(:groupless_student) { @course.enroll_student(User.create!, enrollment_state: :active).user }

  let(:group_selector) { SpeedGrader::StudentGroupSelection.new(current_user: @teacher, course: @course) }

  context "when SpeedGrader is opened for a particular student" do
    context "when no group was previously selected" do
      it "returns the first group containing that student" do
        selection = group_selector.select_group(student_id: group2_student.id)
        expect(selection.group).to eq group2
      end

      it "returns :no_group_selected as the reason for the change" do
        selection = group_selector.select_group(student_id: group2_student.id)
        expect(selection.reason_for_change).to eq :no_group_selected
      end
    end

    context "when a group containing the student was previously selected" do
      it "returns the currently-selected group" do
        @teacher.preferences[:gradebook_settings] = { @course.global_id => { "filter_rows_by" => { "student_group_id" => group1.id.to_s } } }
        @teacher.save!

        selection = group_selector.select_group(student_id: group1_student.id)
        expect(selection.group).to eq group1
      end
    end

    context "when a group that does not contain the student was previously selected" do
      before do
        @teacher.preferences[:gradebook_settings] = { @course.global_id => { "filter_rows_by" => { "student_group_id" => group1.id.to_s } } }
        @teacher.save!
      end

      context "when the selected student belongs to at least one group" do
        it "returns the first group containing that student" do
          selection = group_selector.select_group(student_id: group2_student.id)
          expect(selection.group).to eq group2
        end

        it "returns :student_not_in_selected_group as the reason for the change" do
          selection = group_selector.select_group(student_id: group2_student.id)
          expect(selection.reason_for_change).to eq :student_not_in_selected_group
        end
      end

      context "when the selected student belongs to no groups" do
        it "returns a nil group" do
          selection = group_selector.select_group(student_id: groupless_student.id)
          expect(selection.group).to be_nil
        end

        it "returns :student_in_no_groups as the reason for the change" do
          selection = group_selector.select_group(student_id: groupless_student.id)
          expect(selection.reason_for_change).to eq :student_in_no_groups
        end
      end
    end
  end

  context "when SpeedGrader is opened without reference to a particular student" do
    context "when no group is selected" do
      it "selects the first non-empty group in the course" do
        selection = group_selector.select_group(student_id: nil)
        expect(selection.group).to eq group1
      end

      it "returns :no_group_selected as the reason for the change" do
        selection = group_selector.select_group(student_id: nil)
        expect(selection.reason_for_change).to eq :no_group_selected
      end
    end

    context "when a non-empty group is already selected" do
      before do
        @teacher.preferences[:gradebook_settings] = { @course.global_id => { "filter_rows_by" => { "student_group_id" => group2.id.to_s } } }
        @teacher.save!
      end

      it "does not consider groups with group_memberships where moderator status is nil as being empty" do
        student = @course.enroll_student(User.create!, enrollment_state: :active).user
        nil_moderator_group = category.groups.create!(context: @course)
        nil_moderator_group.add_user(student)
        nil_moderator_group.group_memberships.update_all(moderator: nil)

        @teacher.preferences[:gradebook_settings] = {
          @course.global_id => { "filter_rows_by" => { "student_group_id" => nil_moderator_group.id.to_s } }
        }
        @teacher.save!

        selection = group_selector.select_group(student_id: nil)
        expect(selection.group).to eq nil_moderator_group
      end

      it "returns the currently-selected group" do
        selection = group_selector.select_group(student_id: nil)
        expect(selection.group).to eq group2
      end
    end

    context "when an empty group is already selected" do
      before do
        @teacher.preferences[:gradebook_settings] = { @course.global_id => { "filter_rows_by" => { "student_group_id" => empty_group.id.to_s } } }
        @teacher.save!
      end

      it "returns the first non-empty group in the course" do
        selection = group_selector.select_group(student_id: nil)
        expect(selection.group).to eq group1
      end

      it "returns :no_students_in_group as the reason for the change" do
        selection = group_selector.select_group(student_id: nil)
        expect(selection.reason_for_change).to eq :no_students_in_group
      end
    end
  end
end
