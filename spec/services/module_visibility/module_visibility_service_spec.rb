# frozen_string_literal: true

#
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

require_relative "../../spec_helper"

describe "ModuleVisibility" do
  before :once do
    course_factory(active_all: true)
    @section1 = @course.default_section
    @section2 = @course.course_sections.create!(name: "Section 2")
    @module1 = @course.context_modules.create!(name: "Module 1")
    @module2 = @course.context_modules.create!(name: "Module 2")
    @student1 = student_in_course(active_all: true, section: @section1).user
    @student2 = student_in_course(active_all: true, section: @section2).user
  end

  def module_ids_visible_to_user(user)
    ModuleVisibility::ModuleVisibilityService.modules_visible_to_students(course_ids: @course.id, user_ids: user.id).map(&:context_module_id)
  end

  context "module visibility" do
    it "includes all modules by default" do
      expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module1.id, @module2.id)
    end

    it "does not include unpublished modules" do
      @module1.workflow_state = "unpublished"
      @module1.save!
      expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module2.id)
    end

    it "does not include modules with a section override unless the user is in the section" do
      @module1.assignment_overrides.create!(set: @section2)
      expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module2.id)
      expect(module_ids_visible_to_user(@student2)).to contain_exactly(@module1.id, @module2.id)
    end

    it "does not include modules with an adhoc override unless the user is in the set" do
      override = @module1.assignment_overrides.create!
      override.assignment_override_students.create!(user: @student1)
      expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module1.id, @module2.id)
      expect(module_ids_visible_to_user(@student2)).to contain_exactly(@module2.id)
    end

    it "ignores deleted overrides" do
      @module1.assignment_overrides.create!(set: @section2, workflow_state: "deleted")
      expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module1.id, @module2.id)
      expect(module_ids_visible_to_user(@student2)).to contain_exactly(@module1.id, @module2.id)
    end

    context "with a group override" do
      before :once do
        @course.account.enable_feature!(:assign_to_differentiation_tags)
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @course.account.save!
        @course.account.reload

        @module3 = @course.context_modules.create!(name: "Module 3 for Non-Collaborative Group")

        @student3 = student_in_course(active_all: true).user

        @group_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
        @group_category.create_groups(2)
        @group = @group_category.groups.first
        @group.add_user(@student3, "accepted")

        @module3.assignment_overrides.create!(set: @group)
      end

      it "does not consider differentiation tags when the feature is disabled" do
        @course.account.disable_feature!(:assign_to_differentiation_tags)
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
        @course.account.save!
        @course.account.reload

        expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module1.id, @module2.id)
        expect(module_ids_visible_to_user(@student2)).to contain_exactly(@module1.id, @module2.id)
        expect(module_ids_visible_to_user(@student3)).to contain_exactly(@module1.id, @module2.id)
      end

      it "does not include modules unless the user is in the group" do
        expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module1.id, @module2.id)
        expect(module_ids_visible_to_user(@student2)).to contain_exactly(@module1.id, @module2.id)
        expect(module_ids_visible_to_user(@student3)).to contain_exactly(@module1.id, @module2.id, @module3.id)
      end

      it "ignore group overrides when they are deleted" do
        @group_category.destroy
        @group_category.groups.each(&:destroy)

        expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module1.id, @module2.id)
        expect(module_ids_visible_to_user(@student2)).to contain_exactly(@module1.id, @module2.id)
        expect(module_ids_visible_to_user(@student3)).to contain_exactly(@module1.id, @module2.id)
      end

      it "ignore assignment overrides when they are deleted" do
        @module3.assignment_overrides.destroy_all

        expect(module_ids_visible_to_user(@student1)).to contain_exactly(@module1.id, @module2.id, @module3.id)
        expect(module_ids_visible_to_user(@student2)).to contain_exactly(@module1.id, @module2.id, @module3.id)
        expect(module_ids_visible_to_user(@student3)).to contain_exactly(@module1.id, @module2.id, @module3.id)
      end

      it "does not show module when to student after he is removed from group" do
        @group.group_memberships.where(user: @student3).destroy_all

        expect(module_ids_visible_to_user(@student3)).to contain_exactly(@module1.id, @module2.id)
      end
    end
  end
end
