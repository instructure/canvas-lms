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
#

describe DataFixup::ModuleOverrideDateUpdater do
  describe "ModuleOverrideDateUpdater" do
    before :once do
      AssignmentOverride.class_eval do
        clear_validators!
      end

      course_with_student(course: @course, active_all: true)
      @module = @course.context_modules.create!(name: "Module 1")
      @module_override = @module.assignment_overrides.create!(due_at_overridden: true, lock_at_overridden: true, unlock_at_overridden: true)
      @module_override.assignment_override_students.create!(user: @student)
    end

    it "updates the *overridden values to false" do
      DataFixup::ModuleOverrideDateUpdater.run
      @module_override.reload

      expect(@module_override.due_at_overridden).to be(false)
      expect(@module_override.lock_at_overridden).to be(false)
      expect(@module_override.unlock_at_overridden).to be(false)
    end
  end
end
