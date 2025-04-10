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

    def module_with_two_items
      modules = create_modules(1, true)
      modules[0].add_item({ id: @assignment.id, type: "assignment" })
      modules[0].add_item({ id: @assignment2.id, type: "assignment" })
      get "/courses/#{@course.id}/modules"
      f(".collapse_module_link[aria-controls='context_module_content_#{modules[0].id}']").click
      wait_for_ajaximations
    end

    it_behaves_like "context modules for teachers"

    context "with modules page rewrite feature flag enabled" do
      before do
        @course.root_account.enable_feature!(:modules_page_rewrite)
        module_1 = @course.context_modules.create!(name: "Module 1")
        assignment_1 = @course.assignments.create!(name: "Assignment 1")
        module_1.add_item({ id: assignment_1.id, type: "assignment" })
      end

      it "page renders" do
        get "/courses/#{@course.id}/modules"
        expect(f("[data-testid='modules-rewrite-container']")).to be_present
      end
    end
  end
end
