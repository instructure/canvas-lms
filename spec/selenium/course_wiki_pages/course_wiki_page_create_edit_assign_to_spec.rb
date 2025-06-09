# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/context_modules_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "page_objects/wiki_page"
require_relative "page_objects/wiki_index_page"
require_relative "../conditional_release/page_objects/conditional_release_objects"

describe "wiki pages edit page assign to" do
  include_context "in-process server selenium tests"

  include ContextModulesCommon
  include ItemsAssignToTray
  include CourseWikiPage
  include CourseWikiIndexPage

  before :once do
    course_with_teacher(active_all: true)
    @page = @course.wiki_pages.create!(title: "new_page")
    @section1 = @course.course_sections.create!(name: "section1")
    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  before do
    user_session(@teacher)
  end

  context "assignments embedded on page" do
    it "shows existing enrollments when on the edit page" do
      @page.assignment_overrides.create!(set_type: "ADHOC")
      @page.assignment_overrides.first.assignment_override_students.create!(user: @student1)

      visit_wiki_edit_page(@course.id, @page.title)

      expect(module_item_assign_to_card[0]).to be_displayed
      expect(module_item_assign_to_card[1]).to be_displayed

      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "saves new overrides" do
      expect(@page.assignment_overrides.count).to eq(0)

      visit_wiki_edit_page(@course.id, @page.title)

      click_add_assign_to_card
      select_module_item_assignee(1, @section1.name)

      save_wiki_page

      expect(@page.assignment_overrides.count).to eq(1)
    end

    it "shows 'everyone' card when course overrides exist" do
      @context_module = @course.context_modules.create! name: "Mod"
      module_override = @context_module.assignment_overrides.build
      module_override.course_section = @course.course_sections.first
      module_override.save!
      @context_module.add_item(type: "wiki_page", id: @page.id)

      @page.assignment_overrides.create!(set: @course)
      expect(@page.all_assignment_overrides.count).to eq(2)

      visit_wiki_edit_page(@course.id, @page.title)

      expect(module_item_assign_to_card[0]).to be_displayed
      expect(module_item_assign_to_card[1]).to be_displayed

      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      expect(assign_to_in_tray("Remove #{@course.course_sections.first.name}")[0]).to be_displayed
    end

    it "does not show Manage Assign To for group pages" do
      group = @course.groups.create!(name: "Group 1")
      page = group.wiki_pages.create!(title: "group-page")
      visit_group_wiki_edit_page(group.id, page.title)
      wait_for_ajaximations
      expect(element_exists?(editing_roles_input_selector)).to be_truthy
      expect(element_exists?(assign_to_card_selector)).to be_falsey
    end

    it "does not show the mastery paths checkbox but adds assignment to mastery paths if selected in the tray" do
      @course.conditional_release = true
      @course.save!
      visit_wiki_edit_page(@course.id, @page.title)
      wait_for_ajaximations
      expect(ConditionalReleaseObjects.conditional_content_exists?).to be false

      click_add_assign_to_card
      select_module_item_assignee(1, "Mastery Paths")

      save_wiki_page

      assignment = assignment_model(course: @course, points_possible: 100)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      ConditionalReleaseObjects.last_add_assignment_button.click
      expect(ConditionalReleaseObjects.assignment_selection_modal).to include_text("new_page")
    end

    it "does not show the button when the user does not have the manage_wiki_update permission even if they can edit" do
      @page.update!(editing_roles: "teachers,students")
      visit_wiki_edit_page(@course.id, @page.title)
      expect(element_exists?(assign_to_card_selector)).to be_truthy

      RoleOverride.create!(context: @course.account, permission: "manage_wiki_update", role: teacher_role, enabled: false)
      visit_wiki_edit_page(@course.id, @page.title)
      expect(element_exists?(assign_to_card_selector)).to be_falsey
    end

    context "with course pacing" do
      before do
        @course.enable_course_paces = true
        @course.save!
      end

      it "mark only_visible_to_overrides to false" do
        visit_course_wiki_index_page(@course.id)
        page_index_new_page_btn.click
        wait_for_ajaximations
        wait_for_rce
        replace_wiki_page_name("Course pacing page")

        expect_new_page_load { save_wiki_page }

        page = @course.wiki_pages.last

        expect(page.only_visible_to_overrides).to be_falsey
      end

      context "with mastery paths" do
        before do
          @course.root_account.enable_feature!(:course_pace_pacing_with_mastery_paths)
          @course.update(conditional_release: true)
        end

        it "sets toggles assignment override for mastery paths when mastery path toggle is toggled" do
          visit_wiki_edit_page(@course.id, @page.title)
          mastery_path_toggle.click
          expect_new_page_load { save_wiki_page }

          @page.reload
          expect(@page.assignment.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).to be_present

          visit_wiki_edit_page(@course.id, @page.title)
          mastery_path_toggle.click
          expect_new_page_load { save_wiki_page }

          expect(@page.assignment.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).not_to be_present
        end
      end
    end
  end

  context "differentiation tags" do
    before :once do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: true }
        a.save!
      end

      @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
      @diff_tag1 = @course.groups.create!(name: "Differentiation Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
      @diff_tag1.add_user(@student1)
      @page.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag1.id, title: @diff_tag1.name)
      @page.update!(only_visible_to_overrides: true)
    end

    it "shows the convert override message when diff tags setting disabled" do
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      visit_wiki_edit_page(@course.id, @page.title)
      wait_for_ajaximations
      expect(element_exists?(convert_override_alert_selector)).to be_truthy
    end

    it "clicking convert overrides button converts the override and refreshes the cards" do
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      visit_wiki_edit_page(@course.id, @page.title)
      wait_for_ajaximations
      expect(f(assignee_selected_option_selector).text).to include(@diff_tag1.name)
      f(convert_override_button_selector).click
      wait_for_ajaximations
      expect(f(assignee_selected_option_selector).text).to include(@student1.name)
    end

    it "clicking convert overrides button converts overrides and refreshes the cards" do
      dtc = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
      diff_tag2 = @course.groups.create!(name: "Differentiation Tag 1", group_category: dtc, non_collaborative: true)
      diff_tag2.add_user(@student2)
      @page.assignment_overrides.create!(set_type: "Group", set_id: diff_tag2.id, title: diff_tag2.name)
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      visit_wiki_edit_page(@course.id, @page.title)
      wait_for_ajaximations
      overrides = ff(assignee_selected_option_selector)
      expect(overrides[0].text).to include(@diff_tag1.name)
      expect(overrides[1].text).to include(diff_tag2.name)
      f(convert_override_button_selector).click
      wait_for_ajaximations
      converted_overrides = ff(assignee_selected_option_selector)
      expect(converted_overrides[0].text).to include(@student2.name)
      expect(converted_overrides[1].text).to include(@student1.name)
    end
  end
end
