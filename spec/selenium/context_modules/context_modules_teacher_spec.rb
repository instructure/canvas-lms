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

require_relative "../helpers/context_modules_common"
require_relative "../helpers/public_courses_context"
require_relative "page_objects/modules_index_page"
require_relative "page_objects/modules_settings_tray"
require_relative "../helpers/items_assign_to_tray"
require_relative "shared_examples/context_modules_teacher_shared_examples"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray

  context "as a teacher", priority: "1" do
    before(:once) do
      course_with_teacher(active_all: true)
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

    context "with modules page rewrite feature flag enabled" do
      before do
        @course.root_account.enable_feature!(:modules_page_rewrite)
        module_1 = @course.context_modules.create!(name: "Module 1")
        assignment_1 = @course.assignments.create!(name: "Assignment 1")
        module_1.add_item({ id: assignment_1.id, type: "assignment" })
      end

      it "page renders", :ignore_js_errors do
        get "/courses/#{@course.id}/modules"
        expect(f("[data-testid='modules-rewrite-container']")).to be_present
      end
    end

    context "expanding/collapsing modules" do
      before do
        @mod = create_modules(2, true)
        @mod[0].add_item({ id: @assignment.id, type: "assignment" })
        @mod[1].add_item({ id: @assignment2.id, type: "assignment" })
        get "/courses/#{@course.id}/modules"
      end

      def assert_collapsed
        expect(expand_module_link(@mod[0].id)).to be_displayed
        expect(module_content(@mod[0].id)).not_to be_displayed
        expect(expand_module_link(@mod[1].id)).to be_displayed
        expect(module_content(@mod[1].id)).not_to be_displayed
      end

      def assert_expanded
        expect(f("#context_module_#{@mod[0].id} span.collapse_module_link")).to be_displayed
        expect(f("#context_module_#{@mod[0].id} .content")).to be_displayed
        expect(f("#context_module_#{@mod[1].id} span.collapse_module_link")).to be_displayed
        expect(f("#context_module_#{@mod[1].id} .content")).to be_displayed
      end

      it "displays collapse all button at top of page" do
        button = f("button#expand_collapse_all")
        expect(button).to be_displayed
        expect(button.attribute("data-expand")).to eq("false")
      end

      it "collapses and expand all modules when clicked and persist after refresh" do
        button = f("button#expand_collapse_all")
        button.click
        wait_for_ajaximations
        assert_collapsed
        expect(button.text).to eq("Expand All")
        refresh_page
        assert_collapsed
        button = f("button#expand_collapse_all")
        button.click
        wait_for_ajaximations
        assert_expanded
        expect(button.text).to eq("Collapse All")
        refresh_page
        assert_expanded
      end

      it "collapses all after collapsing individually" do
        f("#context_module_#{@mod[0].id} span.collapse_module_link").click
        wait_for_ajaximations
        button = f("button#expand_collapse_all")
        button.click
        wait_for_ajaximations
        assert_collapsed
        expect(button.text).to eq("Expand All")
      end
    end
  end
end
