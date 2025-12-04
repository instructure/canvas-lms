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
      @course = course_factory(name: "course", active_course: true)
      @course.enable_feature!(:assignment_enhancements_teacher_view)
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

    def select_student(input_field, student_name)
      input_field.send_keys(student_name)
      wait_for_ajaximations
      TeacherViewPageV2.select_student_option(student_name).click
      wait_for_ajaximations
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

    context "student search" do
      before do
        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations
        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations
      end

      it "searches and selects a reviewer" do
        TeacherViewPageV2.target_select_input.send_keys(@student1.name)
        wait_for_ajaximations

        expect(TeacherViewPageV2.select_student_option(@student1.name)).to be_displayed

        TeacherViewPageV2.select_student_option(@student1.name).click
        wait_for_ajaximations

        expect(TeacherViewPageV2.target_select_input.attribute("value")).to eq(@student1.name)
      end

      it "searches and selects a recipient" do
        TeacherViewPageV2.subject_select_input.send_keys(@student2.name)
        wait_for_ajaximations

        expect(TeacherViewPageV2.select_student_option(@student2.name)).to be_displayed

        TeacherViewPageV2.select_student_option(@student2.name).click
        wait_for_ajaximations

        expect(TeacherViewPageV2.subject_select_input.attribute("value")).to eq(@student2.name)
      end

      it "shows all students in search results initially" do
        TeacherViewPageV2.target_select_input.send_keys("Student")
        wait_for_ajaximations

        expect(TeacherViewPageV2.select_student_option(@student1.name)).to be_displayed
        expect(TeacherViewPageV2.select_student_option(@student2.name)).to be_displayed
        expect(TeacherViewPageV2.select_student_option(@student3.name)).to be_displayed
      end

      it "filters search results based on input" do
        TeacherViewPageV2.target_select_input.send_keys("Student 1")
        wait_for_ajaximations

        expect(TeacherViewPageV2.select_student_option(@student1.name)).to be_displayed
        expect(f("body")).not_to contain_jqcss("span[role='option']:contains('#{@student2.name}')")
        expect(f("body")).not_to contain_jqcss("span[role='option']:contains('#{@student3.name}')")
      end

      it "excludes selected reviewer from recipient search" do
        select_student(TeacherViewPageV2.target_select_input, @student1.name)

        TeacherViewPageV2.subject_select_input.send_keys("Student")
        wait_for_ajaximations

        expect(f("body")).not_to contain_jqcss("span[role='option']:contains('#{@student1.name}')")
        expect(TeacherViewPageV2.select_student_option(@student2.name)).to be_displayed
        expect(TeacherViewPageV2.select_student_option(@student3.name)).to be_displayed
      end

      it "excludes selected recipient from reviewer search" do
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.target_select_input.send_keys("Student")
        wait_for_ajaximations

        expect(TeacherViewPageV2.select_student_option(@student1.name)).to be_displayed
        expect(f("body")).not_to contain_jqcss("span[role='option']:contains('#{@student2.name}')")
        expect(TeacherViewPageV2.select_student_option(@student3.name)).to be_displayed
      end

      it "excludes selected recipients from additional subject fields" do
        select_student(TeacherViewPageV2.target_select_input, @student1.name)
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.add_subject_button.click
        wait_for_ajaximations

        TeacherViewPageV2.additional_subject_select_input("1").send_keys("Student")
        wait_for_ajaximations

        expect(f("body")).not_to contain_jqcss("span[role='option']:contains('#{@student1.name}')")
        expect(f("body")).not_to contain_jqcss("span[role='option']:contains('#{@student2.name}')")
        expect(TeacherViewPageV2.select_student_option(@student3.name)).to be_displayed
      end

      it "shows correct labels when switching to reviewee target type" do
        TeacherViewPageV2.target_type_reviewee_radio.click
        wait_for_ajaximations

        expect(fj("label:contains('Recipient Name')")).to be_displayed
        expect(fj("label:contains('Reviewer Name')")).to be_displayed
      end

      it "searches work correctly after switching target type" do
        TeacherViewPageV2.target_type_reviewee_radio.click
        wait_for_ajaximations

        # Target is now recipient
        select_student(TeacherViewPageV2.target_select_input, @student1.name)

        # Subject is now reviewer
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        expect(TeacherViewPageV2.target_select_input.attribute("value")).to eq(@student1.name)
        expect(TeacherViewPageV2.subject_select_input.attribute("value")).to eq(@student2.name)
      end
    end

    context "create allocation rule" do
      before do
        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations
        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations
      end

      it "opens the create rule modal when add rule button is clicked" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.create_rule_modal).to be_displayed
      end

      it "creates a basic allocation rule with reviewer target type" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.target_select_input, @student1.name)
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(1)
        expect(rule_cards.first.text).to include(@student1.name)
        expect(rule_cards.first.text).to include("Must review")
      end

      it "creates a rule with reviewee target type" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        TeacherViewPageV2.target_type_reviewee_radio.click

        select_student(TeacherViewPageV2.target_select_input, @student2.name)
        select_student(TeacherViewPageV2.subject_select_input, @student1.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(1)
        expect(rule_cards.first.text).to include(@student2.name)
        expect(rule_cards.first.text).to include("Must be reviewed by")
      end

      it "creates a rule with different review types" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        TeacherViewPageV2.review_type_should_not_review_radio.click

        select_student(TeacherViewPageV2.target_select_input, @student1.name)
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(1)
        expect(rule_cards.first.text).to include("Should not review")
      end

      it "creates a reciprocal review rule" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        TeacherViewPageV2.target_type_reciprocal_radio.click

        select_student(TeacherViewPageV2.target_select_input, @student1.name)
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(2)
      end

      it "creates a rule with multiple subjects" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.target_select_input, @student1.name)
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.add_subject_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.additional_subject_select_input(1), @student3.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(2)
      end

      it "adds additional subject fields" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        TeacherViewPageV2.add_subject_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.additional_subject_select_input(1)).to be_displayed
      end

      it "removes additional subject field" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        TeacherViewPageV2.add_subject_button.click
        wait_for_ajaximations

        TeacherViewPageV2.delete_additional_subject_field_button(1).click
        wait_for_ajaximations

        expect(element_exists?("input#subject-select-1")).to be_falsey
      end

      it "hides add subject button for reciprocal review type" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.add_subject_button).to be_displayed

        TeacherViewPageV2.target_type_reciprocal_radio.click
        wait_for_ajaximations

        expect(element_exists?("button[data-testid='add-subject-button']")).to be_falsey
      end

      it "clears additional subjects when switching to reciprocal" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        TeacherViewPageV2.add_subject_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.additional_subject_select_input(1)).to be_displayed

        TeacherViewPageV2.target_type_reciprocal_radio.click
        wait_for_ajaximations

        expect(element_exists?("input#subject-select-1")).to be_falsey
      end

      it "shows validation error when target is not selected" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.validation_error_message).to be_displayed
      end

      it "shows validation error when subject is not selected" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.target_select_input, @student1.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.validation_error_message).to be_displayed
      end

      it "focuses on target field when validation fails" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.target_select_input == driver.switch_to.active_element
        end
        expect(TeacherViewPageV2.target_select_input).to eq(driver.switch_to.active_element)
      end

      it "focuses on new field when added" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        TeacherViewPageV2.add_subject_button.click
        wait_for_ajaximations

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.additional_subject_select_input(1) == driver.switch_to.active_element
        end
        expect(TeacherViewPageV2.additional_subject_select_input(1)).to eq(driver.switch_to.active_element)
      end

      it "focuses on previous field when additional field is removed" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.add_subject_button.click
        wait_for_ajaximations

        TeacherViewPageV2.delete_additional_subject_field_button(1).click
        wait_for_ajaximations

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.subject_select_input == driver.switch_to.active_element
        end
        expect(TeacherViewPageV2.subject_select_input).to eq(driver.switch_to.active_element)
      end

      it "focuses on newly created rule's edit button after creation" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.target_select_input, @student1.name)
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.edit_rule_button(rule_cards.first) == driver.switch_to.active_element
        end
        expect(TeacherViewPageV2.edit_rule_button(rule_cards.first)).to eq(driver.switch_to.active_element)
      end

      it "shows an error alert when creation fails" do
        allow_any_instance_of(AllocationRule).to receive(:save!).and_raise(StandardError, "Database error")

        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.target_select_input, @student1.name)
        select_student(TeacherViewPageV2.subject_select_input, @student2.name)

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.create_error_alert).to be_displayed
        expect(TeacherViewPageV2.create_rule_modal).to be_displayed
      end

      it "cancels rule creation when cancel button is clicked" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        select_student(TeacherViewPageV2.target_select_input, @student1.name)

        TeacherViewPageV2.modal_cancel_button.click
        wait_for_ajaximations

        expect(f("body")).not_to contain_css("span[data-testid='create-rule-modal']")
        rule_cards = element_exists?("div[data-testid='allocation-rule-card-wrapper']")
        expect(rule_cards).to be_falsey
      end

      it "closes modal when close button is clicked" do
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.create_rule_modal).to be_displayed
        wait_for_animations

        TeacherViewPageV2.modal_close_button.click
        wait_for_ajaximations

        expect(f("body")).not_to contain_css("span[data-testid='create-rule-modal']")
      end
    end

    context "edit allocation rule" do
      before do
        @rule = AllocationRule.create!(
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
      end

      it "opens the edit rule modal with pre-populated values" do
        rule_cards = TeacherViewPageV2.allocation_rule_cards
        TeacherViewPageV2.edit_rule_button(rule_cards.first).click
        wait_for_ajaximations

        expect(TeacherViewPageV2.edit_rule_modal).to be_displayed
        expect(f("input[data-testid='target-type-reviewer']")).to be_checked
        expect(f("input[data-testid='review-type-must-review']")).to be_checked
      end

      it "edits an existing allocation rule" do
        rule_cards = TeacherViewPageV2.allocation_rule_cards
        TeacherViewPageV2.edit_rule_button(rule_cards.first).click
        wait_for_ajaximations

        TeacherViewPageV2.review_type_should_review_radio.click

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.first.text).to include("Should review")
      end

      it "focuses on edited rule's edit button after save" do
        rule_cards = TeacherViewPageV2.allocation_rule_cards
        TeacherViewPageV2.edit_rule_button(rule_cards.first).click
        wait_for_ajaximations

        TeacherViewPageV2.review_type_should_review_radio.click

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        wait_for(method: nil, timeout: 2) do
          active_element = driver.switch_to.active_element
          active_element.attribute("id").to_s.start_with?("edit-rule-button-")
        end

        active_element = driver.switch_to.active_element
        expect(active_element.attribute("id")).to start_with("edit-rule-button-")
      end

      it "shows an error alert when edit fails" do
        allow_any_instance_of(AllocationRule).to receive(:save!).and_raise(StandardError, "Database error")

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        TeacherViewPageV2.edit_rule_button(rule_cards.first).click
        wait_for_ajaximations

        TeacherViewPageV2.review_type_should_review_radio.click

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.edit_error_alert).to be_displayed
        expect(TeacherViewPageV2.edit_rule_modal).to be_displayed
      end

      it "cancels edit without making changes" do
        rule_cards = TeacherViewPageV2.allocation_rule_cards
        original_text = rule_cards.first.text

        TeacherViewPageV2.edit_rule_button(rule_cards.first).click
        wait_for_ajaximations

        TeacherViewPageV2.modal_cancel_button.click
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.first.text).to eq(original_text)
      end

      it "closes modal when saving without changes" do
        rule_cards = TeacherViewPageV2.allocation_rule_cards
        TeacherViewPageV2.edit_rule_button(rule_cards.first).click
        wait_for_ajaximations

        TeacherViewPageV2.modal_save_button.click
        wait_for_ajaximations

        expect(f("body")).not_to contain_css("span[data-testid='edit-rule-modal']")
      end
    end

    context "allocation rules tray search" do
      before do
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
          assessor: @student2,
          assessee: @student3,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )

        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student3,
          assessee: @student1,
          must_review: true,
          review_permitted: true,
          applies_to_assessor: true
        )
      end

      def navigate_to_tray
        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations
        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations
      end

      it "displays search input when rules exist" do
        navigate_to_tray
        expect(TeacherViewPageV2.allocation_rules_search_input).to be_displayed
      end

      it "filters allocation rules based on student name (as reviewer or recipient)" do
        navigate_to_tray
        # Student 1 appears in 2 rules: as assessor in rule 1, and as assessee in rule 3
        TeacherViewPageV2.allocation_rules_search_input.send_keys(@student1.name)

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.allocation_rule_cards.length == 2
        end

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(2)
        rule_cards.each do |card|
          expect(card.text).to include(@student1.name)
        end
      end

      it "filters allocation rules for another student" do
        navigate_to_tray
        # Student 2 appears in 2 rules: as assessee in rule 1, and as assessor in rule 2
        TeacherViewPageV2.allocation_rules_search_input.send_keys(@student2.name)

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.allocation_rule_cards.length == 2
        end

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(2)
        rule_cards.each do |card|
          expect(card.text).to include(@student2.name)
        end
      end

      it "shows multiple matching rules when search matches multiple students" do
        navigate_to_tray
        TeacherViewPageV2.allocation_rules_search_input.send_keys("Student")
        wait_for_ajaximations

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(3)
      end

      it "shows no results message when search has no matches" do
        navigate_to_tray
        TeacherViewPageV2.allocation_rules_search_input.send_keys("Nonexistent Student")
        wait_for_ajaximations

        expect(TeacherViewPageV2.no_search_results_message).to be_displayed
        expect(TeacherViewPageV2.no_search_results_message.text).to include("No matching results")
      end

      it "clears search results when clear button is clicked" do
        navigate_to_tray
        TeacherViewPageV2.allocation_rules_search_input.send_keys(@student1.name)

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.allocation_rule_cards.length == 2
        end

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(2)

        TeacherViewPageV2.clear_search_button.click

        wait_for(method: nil, timeout: 2) do
          TeacherViewPageV2.allocation_rule_cards.length == 3
        end

        rule_cards = TeacherViewPageV2.allocation_rule_cards
        expect(rule_cards.length).to eq(3)
        expect(TeacherViewPageV2.allocation_rules_search_input.attribute("value")).to eq("")
      end

      it "shows validation error for single character search" do
        navigate_to_tray
        TeacherViewPageV2.allocation_rules_search_input.send_keys("S")
        wait_for_ajaximations

        expect(fj("span:contains('Search term must be at least 2 characters long')")).to be_displayed
      end

      context "with pagination" do
        before do
          10.times do |i|
            student = student_in_course(name: "Extra Student #{i}", course: @course, enrollment_state: :active).user
            AllocationRule.create!(
              course: @course,
              assignment: @assignment,
              assessor: @student1,
              assessee: student,
              must_review: true,
              review_permitted: true,
              applies_to_assessor: true
            )
          end
        end

        it "maintains search filter when navigating pages" do
          navigate_to_tray

          TeacherViewPageV2.wait_for_spinner { TeacherViewPageV2.allocation_rules_search_input.send_keys(@student1.name) }
          wait_for_ajaximations

          first_page_cards = TeacherViewPageV2.allocation_rule_cards
          first_page_cards.each do |card|
            expect(card.text).to include(@student1.name)
          end

          TeacherViewPageV2.pagination_button("2").click
          wait_for_ajaximations

          second_page_cards = TeacherViewPageV2.allocation_rule_cards
          second_page_cards.each do |card|
            expect(card.text).to include(@student1.name)
          end
        end
      end

      it "shows an error alert when fetching allocation rules fails" do
        allow_any_instance_of(Assignment).to receive(:allocation_rules).and_raise(StandardError, "Database error")

        navigate_to_tray
        expect(TeacherViewPageV2.fetch_rules_error_alert).to be_displayed
      end
    end

    context "peer review status hints" do
      before do
        TeacherViewPageV2.visit(@course, @assignment)
        TeacherViewPageV2.peer_review_tab.click
        wait_for_ajaximations
        TeacherViewPageV2.peer_review_allocation_rules_link.click
        wait_for_ajaximations
        TeacherViewPageV2.add_rule_button.click
        wait_for_ajaximations
      end

      context "when student has completed required peer reviews" do
        before do
          @submission1 = @assignment.submit_homework(@student1, {
                                                       submission_type: "online_text_entry",
                                                       body: "Student 1 submission"
                                                     })
          @submission2 = @assignment.submit_homework(@student2, {
                                                       submission_type: "online_text_entry",
                                                       body: "Student 2 submission"
                                                     })
          @submission3 = @assignment.submit_homework(@student3, {
                                                       submission_type: "online_text_entry",
                                                       body: "Student 3 submission"
                                                     })

          # Student 1 has completed 2 peer reviews (meets required count of 2)
          AssessmentRequest.create!(
            asset: @submission2,
            assessor_asset: @submission1,
            user: @student2,
            assessor: @student1,
            workflow_state: "completed"
          )
          AssessmentRequest.create!(
            asset: @submission3,
            assessor_asset: @submission1,
            user: @student3,
            assessor: @student1,
            workflow_state: "completed"
          )
        end

        it "shows hint text when selecting reviewer who completed reviews" do
          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("#{@student1.name} has already completed the required peer reviews")
        end

        it "shows hint text when selecting subject in reviewee mode" do
          TeacherViewPageV2.target_type_reviewee_radio.click
          wait_for_ajaximations

          select_student(TeacherViewPageV2.target_select_input, @student2.name)
          select_student(TeacherViewPageV2.subject_select_input, @student1.name)

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("#{@student1.name} has already completed the required peer reviews")
        end
      end

      context "when student has enough must review allocations" do
        before do
          # Student 1 has 2 must review allocations (meets required count of 2)
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
        end

        it "shows hint text when selecting reviewer with enough must review allocations" do
          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("#{@student1.name} already has enough")
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("must review")
        end

        it "shows hint text when selecting additional subject in reviewee mode" do
          TeacherViewPageV2.target_type_reviewee_radio.click
          wait_for_ajaximations

          select_student(TeacherViewPageV2.target_select_input, @student2.name)
          select_student(TeacherViewPageV2.subject_select_input, @student3.name)

          TeacherViewPageV2.add_subject_button.click
          wait_for_ajaximations

          select_student(TeacherViewPageV2.additional_subject_select_input(1), @student1.name)

          hints = TeacherViewPageV2.peer_review_status_hints
          expect(hints.length).to eq(1)
          expect(hints.first.text).to include("#{@student1.name} already has enough")
          expect(hints.first.text).to include("must review")
        end

        it "does not show hint when must review type is not selected" do
          TeacherViewPageV2.review_type_should_review_radio.click
          wait_for_ajaximations

          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          expect(element_exists?("div[data-testid='peer-review-status-hint']")).to be_falsey
        end
      end

      context "when student's completed + must review count meets requirement" do
        before do
          @submission1 = @assignment.submit_homework(@student1, {
                                                       submission_type: "online_text_entry",
                                                       body: "Student 1 submission"
                                                     })
          @submission2 = @assignment.submit_homework(@student2, {
                                                       submission_type: "online_text_entry",
                                                       body: "Student 2 submission"
                                                     })

          # Student 1 has completed 1 review
          AssessmentRequest.create!(
            asset: @submission2,
            assessor_asset: @submission1,
            user: @student2,
            assessor: @student1,
            workflow_state: "completed"
          )

          # Student 1 has 1 must review allocation (total = 2, meets requirement)
          AllocationRule.create!(
            course: @course,
            assignment: @assignment,
            assessor: @student1,
            assessee: @student3,
            must_review: true,
            review_permitted: true,
            applies_to_assessor: true
          )
        end

        it "shows hint text when selecting reviewer with combined count" do
          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("#{@student1.name} already has enough")
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("must review")
        end

        it "shows hint text in reciprocal review mode" do
          TeacherViewPageV2.target_type_reciprocal_radio.click
          wait_for_ajaximations

          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("#{@student1.name} already has enough")
          expect(TeacherViewPageV2.peer_review_status_hint.text).to include("must review")
        end
      end

      context "when switching between review types" do
        before do
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
        end

        it "shows hint when must review is selected" do
          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed
        end

        it "hides hint when switching to should review" do
          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed

          TeacherViewPageV2.review_type_should_review_radio.click
          wait_for_ajaximations

          expect(element_exists?("div[data-testid='peer-review-status-hint']")).to be_falsey
        end

        it "shows hint again when switching back to must review" do
          select_student(TeacherViewPageV2.target_select_input, @student1.name)

          TeacherViewPageV2.review_type_should_review_radio.click
          wait_for_ajaximations

          expect(element_exists?("div[data-testid='peer-review-status-hint']")).to be_falsey

          TeacherViewPageV2.review_type_must_review_radio.click
          wait_for_ajaximations

          expect(TeacherViewPageV2.peer_review_status_hint).to be_displayed
        end
      end

      context "flash success messages" do
        before do
          TeacherViewPageV2.visit(@course, @assignment)
          TeacherViewPageV2.peer_review_tab.click
          wait_for_ajaximations
          TeacherViewPageV2.peer_review_allocation_rules_link.click
          wait_for_ajaximations
        end

        it "shows success message when creating a new rule" do
          TeacherViewPageV2.add_rule_button.click
          wait_for_ajaximations

          select_student(TeacherViewPageV2.target_select_input, @student1.name)
          select_student(TeacherViewPageV2.subject_select_input, @student2.name)

          TeacherViewPageV2.modal_save_button.click
          wait_for_ajaximations

          expect_instui_flash_message("New rule has been created successfully")

          rule_cards = TeacherViewPageV2.allocation_rule_cards
          expect(rule_cards.length).to eq(1)
        end

        it "shows success message when editing a rule" do
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
          TeacherViewPageV2.edit_rule_button(rule_cards.first).click
          wait_for_ajaximations

          TeacherViewPageV2.review_type_should_review_radio.click

          TeacherViewPageV2.modal_save_button.click
          wait_for_ajaximations

          expect_instui_flash_message("Rule has been edited successfully")
        end

        it "shows success message when deleting a rule" do
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
          TeacherViewPageV2.delete_allocation_rule_button(rule_cards.first).click
          wait_for_ajaximations

          expect_instui_flash_message("Rule has been deleted successfully")

          expect(element_exists?("div[data-testid='allocation-rule-card-wrapper']")).to be_falsey
        end
      end

      context "ESC key accessibility" do
        it "closes allocation rules tray and create rule modal with ESC key" do
          TeacherViewPageV2.visit(@course, @assignment)
          TeacherViewPageV2.peer_review_tab.click
          wait_for_ajaximations

          TeacherViewPageV2.peer_review_allocation_rules_link.click
          wait_for_ajaximations
          expect(TeacherViewPageV2.allocation_rules_tray).to be_displayed

          TeacherViewPageV2.add_rule_button.click
          wait_for_ajaximations
          expect(TeacherViewPageV2.create_rule_modal).to be_displayed
          expect(element_exists?("div[role='dialog'][aria-label='Allocation Rules']")).to be_truthy

          driver.action.send_keys(:escape).perform
          wait_for_ajaximations

          expect(element_exists?("span[data-testid='create-rule-modal']")).to be_falsey
          expect(TeacherViewPageV2.allocation_rules_tray).to be_displayed

          driver.action.send_keys(:escape).perform
          wait_for_ajaximations

          expect(element_exists?("div[role='dialog'][aria-label='Allocation Rules']")).to be_falsey
        end
      end
    end
  end
end
