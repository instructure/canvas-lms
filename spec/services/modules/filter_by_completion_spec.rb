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
#

require_relative "../../spec_helper"

describe Modules::FilterByCompletion do
  before :once do
    @course = course_factory(active_all: true)
    @student = student_in_course(course: @course, active_all: true).user
    @teacher = teacher_in_course(course: @course, active_all: true).user

    # Create modules with different completion states
    @completed_module = @course.context_modules.create!(name: "Completed Module")
    @started_module = @course.context_modules.create!(name: "Started Module")
    @unlocked_module = @course.context_modules.create!(name: "Unlocked Module")
    @locked_module = @course.context_modules.create!(name: "Locked Module")
    @no_progression_module = @course.context_modules.create!(name: "No Progression Module")

    # Create progressions and ensure they're persisted before tests run
    @completed_progression = @completed_module.context_module_progressions.create!(
      user: @student,
      workflow_state: "completed",
      completed_at: 1.day.ago
    )

    @started_progression = @started_module.context_module_progressions.create!(
      user: @student,
      workflow_state: "started"
    )

    @unlocked_progression = @unlocked_module.context_module_progressions.create!(
      user: @student,
      workflow_state: "unlocked"
    )

    @locked_progression = @locked_module.context_module_progressions.create!(
      user: @student,
      workflow_state: "locked"
    )

    # Ensure all progressions are committed to the database before tests run
    [@completed_progression, @started_progression, @unlocked_progression, @locked_progression].each(&:reload)
  end

  let(:all_modules) { @course.context_modules.active }

  def build_filter_service(status, target_user = @student, current_user = @student)
    described_class.new(all_modules, status, target_user, current_user, @course)
  end

  describe "#filter" do
    context "when filtering for the current user" do
      it "returns completed modules" do
        service = described_class.new(all_modules, "completed", @student, @student, @course)
        result = service.filter

        expect(result).to include(@completed_module)
        expect(result).not_to include(@started_module, @unlocked_module, @locked_module, @no_progression_module)
      end

      it "returns incomplete modules" do
        service = described_class.new(all_modules, "incomplete", @student, @student, @course)
        result = service.filter

        expect(result).to include(@started_module, @unlocked_module, @locked_module, @no_progression_module)
        expect(result).not_to include(@completed_module)
      end

      it "returns not started modules" do
        service = described_class.new(all_modules, "not_started", @student, @student, @course)
        result = service.filter

        expect(result).to include(@unlocked_module, @locked_module, @no_progression_module)
        expect(result).not_to include(@completed_module, @started_module)
      end

      it "returns in progress modules" do
        service = described_class.new(all_modules, "in_progress", @student, @student, @course)
        result = service.filter

        expect(result).to include(@started_module)
        expect(result).not_to include(@completed_module, @unlocked_module, @locked_module, @no_progression_module)
      end

      it "returns all modules for unknown status" do
        service = described_class.new(all_modules, "unknown", @student, @student, @course)
        result = service.filter

        expect(result.count).to eq(5)
      end
    end

    context "when filtering for another user" do
      it "allows filtering for any user (permissions are checked at GraphQL layer)" do
        service = build_filter_service("completed", @student, @teacher)
        result = service.filter

        expect(result).to include(@completed_module)
        expect(result).not_to include(@started_module)
      end

      it "returns correct results for different user" do
        other_student = user_factory(active_all: true)
        @course.enroll_student(other_student, enrollment_state: "active")

        # Other student has no completed modules
        service = build_filter_service("completed", other_student, @teacher)
        result = service.filter

        expect(result).to be_empty
      end
    end
  end
end
