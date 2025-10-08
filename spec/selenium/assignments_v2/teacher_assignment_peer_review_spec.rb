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

require_relative "page_objects/teacher_assignment_page_v2"
require_relative "../common"

describe "as a teacher" do
  specs_require_sharding

  include_context "in-process server selenium tests"

  context "peer review allocation rules" do
    before(:once) do
      Account.default.enable_feature!(:assignment_enhancements_teacher_view)
      @course = course_factory(name: "course", active_course: true)
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
      @student1 = student_in_course(name: "Student 1", course: @course, enrollment_state: :active).user
      @student2 = student_in_course(name: "Student 2", course: @course, enrollment_state: :active).user
      @student3 = student_in_course(name: "Student 3", course: @course, enrollment_state: :active).user
      @assignment = @course.assignments.create!(
        name: "peer review assignment",
        due_at: 5.days.from_now,
        points_possible: 10,
        submission_types: "online_text_entry",
        workflow_state: "published",
        peer_reviews: true,
        peer_review_count: 2
      )
    end

    before do
      user_session(@teacher)
    end

    context "delete allocation rule" do
      it "opens the allocation rules tray when the link is clicked" do
        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations

        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations
        expect(TeacherViewPageV2.allocation_rules_tray).to be_displayed
      end

      it "deletes an allocation rule and updates the UI" do
        # Create an allocation rule
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations

        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(1)

        TeacherViewPageV2.delete_allocation_rule_button(rule_cards.first).click
        wait_for_ajaximations

        expect(element_exists?("div[data-testid='allocation-rule-card-wrapper']")).to be_falsey
      end

      it "deletes multiple allocation rules one by one" do
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student3,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations

        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(2)

        TeacherViewPageV2.delete_allocation_rule_button(rule_cards.first).click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(1)

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.edit_rule_button(rule_cards.first) == driver.switch_to.active_element
        end
        expect(TeacherViewPageV2.edit_rule_button(rule_cards.first)).to eq(driver.switch_to.active_element)

        TeacherViewPageV2.delete_allocation_rule_button(rule_cards.first).click
        wait_for_ajaximations

        expect(element_exists?("div[data-testid='allocation-rule-card-wrapper']")).to be_falsey

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.add_rule_button == driver.switch_to.active_element
        end
        expect(TeacherViewPageV2.add_rule_button).to eq(driver.switch_to.active_element)
      end

      it "closes the allocation rules tray when the close button is clicked" do
        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations

        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations
        expect(TeacherViewPageV2.allocation_rules_tray).to be_displayed

        TeacherViewPageV2.allocation_rules_tray_close_button.click
        wait_for_ajaximations

        expect(f("body")).not_to contain_css('span[data-testid="allocation-rules-tray-close-button"]')
      end

      it "shows an error alert when deletion fails" do
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        allow_any_instance_of(AllocationRule).to receive(:destroy).and_raise(StandardError, "Database error")

        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations

        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(1)

        TeacherViewPageV2.delete_allocation_rule_button(rule_cards.first).click
        wait_for_ajaximations

        expect(TeacherViewPageV2.delete_error_alert).to be_displayed

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(1)
      end
    end
  end
end
