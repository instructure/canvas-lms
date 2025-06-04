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
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/context_modules_teacher_shared_examples"
require_relative "../shared_examples/modules_performance_shared_examples"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5Common
  include K5DashboardPageObject
  include K5DashboardCommonPageObject

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

    it_behaves_like "context modules for teachers"

    context "when the module is empty" do
      before(:once) do
        @empty_module = @course.context_modules.create!(name: "empty module")
      end

      it "displays an empty module" do
        get "/courses/#{@course.id}/modules"
        expect(context_module(@empty_module.id)).to contain_css(module_file_drop_selector)
      end

      it "collapses and expands" do
        get "/courses/#{@course.id}/modules"
        collapse_module_link(@empty_module.id).click
        expect(f(module_file_drop_selector)).not_to be_displayed
        expand_module_link(@empty_module.id).click
        expect(f(module_file_drop_selector)).to be_displayed
      end

      it "collapses after duplication" do
        get "/courses/#{@course.id}/modules"
        duplicate_module(@empty_module)
        expect(f(module_file_drop_selector)).to be_displayed
        collapse_module_link(@empty_module.id).click
        expect(f(module_file_drop_selector)).not_to be_displayed
      end
    end

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

        wait_for_ajaximations

        manage_module_item_button(module_item).click
        click_manage_module_item_assign_to(module_item)

        expect(item_tray_exists?).to be true
      end

      it "duplicates the module item" do
        module_with_two_items
        module_item = ContentTag.last

        manage_module_item_button(module_item).click
        click_module_item_duplicate(module_item)
        wait_for_ajaximations

        module_item = ContentTag.last
        expect(module_item.title).to eq("assignment 2 Copy")
      end

      it "bring up the module item move tray" do
        module_with_two_items
        module_item = ContentTag.last

        manage_module_item_button(module_item).click
        click_module_item_move(module_item)
        wait_for_ajaximations

        expect(move_tray_exists?).to be true
      end

      it "bring up the module item send to tray" do
        module_with_two_items
        module_item = ContentTag.last
        manage_module_item_button(module_item).click
        click_module_item_send_to(module_item)
        wait_for_ajaximations

        expect(send_to_dialog_exists?).to be true
      end

      it "bring up the module item copy to tray", :ignore_js_errors do
        module_with_two_items
        module_item = ContentTag.last

        manage_module_item_button(module_item).click
        click_module_item_copy_to(module_item)
        wait_for_ajaximations

        expect(copy_to_tray_exists?).to be true
      end
    end
  end

  context "as a teacher with many module items on the modules page" do
    before(:once) do
      course_with_teacher(active_all: true)

      @course.account.enable_feature!(:modules_perf)
      Setting.set("module_perf_threshold", -1)

      @module_list = big_course_setup
      @course.reload
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module performance with module items", :context_modules
    it_behaves_like "module performance with module items", :course_homepage
  end

  context "as a canvas for elementary teacher with many module items", :ignore_js_errors do
    before(:once) do
      teacher_setup
      @subject_course.account.enable_feature!(:modules_perf)
      Setting.set("module_perf_threshold", -1)
      @course = @subject_course
      @module_list = big_course_setup
      @subject_course.reload
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module performance with module items", :canvas_for_elementary
  end

  context "as teacher with module items to add, update, show", :ignore_js_errors do
    before(:once) do
      course_with_teacher(active_all: true)

      @course.account.enable_feature!(:modules_perf)
      Setting.set("module_perf_threshold", -1)

      @module = @course.context_modules.create!(name: "module 1")
      11.times do |i|
        @module.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment #{i}").id)
      end
      @course.reload
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module show all or less", :context_modules
    it_behaves_like "module show all or less", :course_homepage

    it_behaves_like "add module items to list", :context_modules
    it_behaves_like "add module items to list", :course_homepage

    it_behaves_like "module moving items", :context_modules
    it_behaves_like "module moving items", :course_homepage
  end

  context "as a canvas for elementary teacher with module items to show", :ignore_js_errors do
    before(:once) do
      teacher_setup
      @subject_course.account.enable_feature!(:modules_perf)
      Setting.set("module_perf_threshold", -1)
      @course = @subject_course
      @module = @course.context_modules.create!(name: "module 1")
      11.times do |i|
        @module.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment #{i}").id)
      end
      @subject_course.reload
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module show all or less", :canvas_for_elementary
    it_behaves_like "add module items to list", :canvas_for_elementary

    # C4E is very challenging with the modules page and scrolling to items
    # is proving to be very flakey, so leaving this out for now.
    # it_behaves_like "module moving items",:canvas_for_elementary
  end
end
