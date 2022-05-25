# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../helpers/assignments_common"
require_relative "../helpers/differentiated_assignments"

describe "interaction with differentiated assignments/quizzes/discusssions in modules" do
  include_context "in-process server selenium tests"
  include DifferentiatedAssignments
  include AssignmentsCommon

  def expect_module_to_have_items(module_item)
    expect(f("#context_module_#{module_item.id}")).to include_text(@da_assignment.title)
    expect(f("#context_module_#{module_item.id}")).to include_text(@da_discussion.title)
    expect(f("#context_module_#{module_item.id}")).to include_text(@da_quiz.title)
  end

  def expect_module_to_not_have_items(module_item)
    expect(f("#context_module_#{module_item.id}")).not_to include_text(@da_assignment.title)
    expect(f("#context_module_#{module_item.id}")).not_to include_text(@da_discussion.title)
    expect(f("#context_module_#{module_item.id}")).not_to include_text(@da_quiz.title)
  end

  context "Student" do
    before do
      course_with_student_logged_in
      da_setup
      da_module_setup
    end

    it "does not show inaccessible module items" do
      create_section_overrides(@section1)
      get "/courses/#{@course.id}/modules"
      expect_module_to_not_have_items(@module)
    end

    it "displays module items with overrides" do
      create_section_overrides(@default_section)
      get "/courses/#{@course.id}/modules"
      expect_module_to_have_items(@module)
    end

    it "does not show unassigned module items with graded submissions" do
      grade_da_assignments
      get "/courses/#{@course.id}/modules"
      expect_module_to_not_have_items(@module)
    end

    it "ignores completion requirements of inaccessible module items" do
      create_section_override_for_assignment(@da_discussion.assignment)
      create_section_override_for_assignment(@da_quiz)
      create_section_override_for_assignment(@da_assignment, course_section: @section1)
      @module.completion_requirements = { @tag_assignment.id => { type: "must_view" },
                                          @tag_discussion.id => { type: "must_view" },
                                          @tag_quiz.id => { type: "must_view" } }
      @module.save
      expect(@module.evaluate_for(@student).workflow_state).to include("unlocked")
      get "/courses/#{@course.id}/modules/items/#{@tag_discussion.id}"
      get "/courses/#{@course.id}/modules/items/#{@tag_quiz.id}"
      # confirm canvas believes this module is now completed despite the invisible assignment not having been viewed
      expect(@module.evaluate_for(@student).workflow_state).to include("completed")
    end
  end

  context "Observer" do
    context "with a student attached" do
      before do
        observer_setup
        da_setup
        da_module_setup
      end

      it "does not show inaccessible module items", priority: "1" do
        create_section_overrides(@section1)
        get "/courses/#{@course.id}/modules"
        expect_module_to_not_have_items(@module)
      end

      it "displays module items with overrides", priority: "1" do
        create_section_overrides(@default_section)
        get "/courses/#{@course.id}/modules"
        expect_module_to_have_items(@module)
      end

      it "does not show unassigned module items with graded submissions", priority: "1" do
        grade_da_assignments
        get "/courses/#{@course.id}/modules"
        expect_module_to_not_have_items(@module)
      end
    end

    context "without a student attached" do
      before do
        course_with_observer_logged_in
        da_setup
        da_module_setup
      end

      it "displays all module items" do
        get "/courses/#{@course.id}/modules"
        expect_module_to_have_items(@module)
      end
    end
  end
end
