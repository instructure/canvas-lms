# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

##############################################################################
# This file is mostly a copy of ../context_modules_teacher_spec.rb, but with
# the tests run with module item lazy loading turned on to validate we are
# still rendering them correctly.
##############################################################################

require_relative "../../helpers/context_modules_common"
require_relative "../../helpers/public_courses_context"
require_relative "../page_objects/modules_index_page"
require_relative "../page_objects/modules_settings_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../shared_examples/context_modules_teacher_shared_examples"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray

  context "as a teacher", priority: "1" do
    before(:once) do
      course_with_teacher(active_all: true)

      @course.account.enable_feature!(:modules_perf)
      Setting.set("module_perf_threshold", -1)
      # have to add quiz and assignment to be able to add them to a new module
      @quiz = @course.assignments.create!(title: "quiz assignment", submission_types: "online_quiz")
      @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
      @assignment2 = @course.assignments.create!(title: "assignment 2",
                                                 submission_types: "online_text_entry",
                                                 due_at: 2.days.from_now,
                                                 points_possible: 10)
      @assignment3 = @course.assignments.create!(title: "assignment 3", submission_types: "online_text_entry")

      @ag1 = @course.assignment_groups.create!(name: "Assignment Group 1")
      @ag2 = @course.assignment_groups.create!(name: "Assignment Group 2")
      @course.reload
    end

    before do
      user_session(@teacher)
    end

    def module_with_two_items
      modules = create_modules(1, true)
      modules[0].add_item({ id: @assignment.id, type: "assignment" })
      modules[0].add_item({ id: @assignment2.id, type: "assignment" })
      get "/courses/#{@course.id}/modules"
      collapse_module_link(modules[0].id).click
      wait_for_ajaximations
    end

    it_behaves_like "context modules for teachers"

    context "when lazy loading fails" do
      it "displays an error message" do
        allow_any_instance_of(ContextModulesController).to receive(:items_html).and_raise(404)
        module_with_two_items
        expect(f(".context_module .content").text).to match("Items failed to load")
        retry_button = f('[data-testid="retry-items-failed-to-load"]')
        expect(retry_button).to be_displayed
        allow_any_instance_of(ContextModulesController).to receive(:items_html).and_call_original
        retry_button.click
        wait_for_ajax_requests
        expect(ff(".context_module .content .context_module_item")).to have_size(2)
      end
    end

    context "when module item actions are selected" do
      it "shows the module item assign to tray" do
        module_with_two_items
        module_item = ContentTag.last
        first_module = ContextModule.last

        expand_module_link(first_module.id).click
        wait_for_ajaximations

        manage_module_item_button(module_item).click
        click_manage_module_item_assign_to(module_item)

        expect(item_tray_exists?).to be true
      end

      it "duplicates the module item" do
        module_with_two_items
        module_item = ContentTag.last
        first_module = ContextModule.last

        expand_module_link(first_module.id).click

        manage_module_item_button(module_item).click
        click_module_item_duplicate(module_item)
        wait_for_ajaximations

        module_item = ContentTag.last
        expect(module_item.title).to eq("assignment 2 Copy")
      end

      it "bring up the module item move tray" do
        module_with_two_items
        module_item = ContentTag.last
        first_module = ContextModule.last

        expand_module_link(first_module.id).click

        manage_module_item_button(module_item).click
        click_module_item_move(module_item)
        wait_for_ajaximations

        expect(move_tray_exists?).to be true
      end

      it "bring up the module item send to tray" do
        module_with_two_items
        module_item = ContentTag.last
        first_module = ContextModule.last

        expand_module_link(first_module.id).click

        manage_module_item_button(module_item).click
        click_module_item_send_to(module_item)
        wait_for_ajaximations

        expect(send_to_dialog_exists?).to be true
      end

      it "bring up the module item copy to tray", :ignore_js_errors do
        module_with_two_items
        module_item = ContentTag.last
        first_module = ContextModule.last

        expand_module_link(first_module.id).click

        manage_module_item_button(module_item).click
        click_module_item_copy_to(module_item)
        wait_for_ajaximations

        expect(copy_to_tray_exists?).to be true
      end
    end
  end
end
