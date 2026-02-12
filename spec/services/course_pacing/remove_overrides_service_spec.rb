# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe CoursePacing::RemoveOverridesService do
  before :once do
    @course = course_model
    @course.enable_course_paces = true
    @course.save!

    @assignment1 = @course.assignments.create!(title: "Assignment 1")
    @assignment2 = @course.assignments.create!(title: "Assignment 2")

    @student1 = user_model
    @student2 = user_model
    @course.enroll_student(@student1, enrollment_state: "active")
    @course.enroll_student(@student2, enrollment_state: "active")

    @course_pacing_override1 = @assignment1.assignment_overrides.create!(
      title: "Course Pacing",
      set_type: "ADHOC",
      due_at_overridden: true,
      due_at: 1.day.from_now
    )
    @course_pacing_override1.assignment_override_students.create!(user: @student1)

    @course_pacing_override2 = @assignment2.assignment_overrides.create!(
      title: "Course Pacing",
      set_type: "ADHOC",
      due_at_overridden: true,
      due_at: 2.days.from_now
    )
    @course_pacing_override2.assignment_override_students.create!(user: @student2)

    @manual_override = @assignment1.assignment_overrides.create!(
      title: "Manual Override",
      set_type: "ADHOC",
      due_at_overridden: true,
      due_at: 3.days.from_now
    )
    @manual_override.assignment_override_students.create!(user: @student2)
  end

  describe ".call" do
    it "removes all Course Pacing overrides" do
      expect(@assignment1.assignment_overrides.active.count).to eq(2)
      expect(@assignment2.assignment_overrides.active.count).to eq(1)

      described_class.call(@course.id)

      expect(@assignment1.assignment_overrides.active.where(title: "Course Pacing").count).to eq(0)
      expect(@assignment2.assignment_overrides.active.where(title: "Course Pacing").count).to eq(0)
    end

    it "does not remove manual overrides" do
      described_class.call(@course.id)

      expect(@assignment1.assignment_overrides.active.where(title: "Manual Override").count).to eq(1)
      expect(@manual_override.reload).to be_active
    end

    it "returns the count of overrides removed" do
      count = described_class.call(@course.id)

      expect(count).to eq(2)
    end

    it "logs statsd metric when overrides are removed" do
      expect(InstStatsd::Statsd).to receive(:count).with("course_pacing.overrides_removed_on_disable", 2)

      described_class.call(@course.id)
    end

    it "does not log statsd metric when no overrides are removed" do
      empty_course = course_model

      expect(InstStatsd::Statsd).not_to receive(:count)

      described_class.call(empty_course.id)
    end

    it "handles courses with no assignments" do
      empty_course = course_model

      expect { described_class.call(empty_course.id) }.not_to raise_error
    end

    it "returns nil if course is not found" do
      result = described_class.call(999_999_999)

      expect(result).to be_nil
    end

    it "clears assignment caches after removing overrides" do
      expect(Assignment).to receive(:clear_cache_keys).with(anything, :availability).at_least(:once)
      expect(SubmissionLifecycleManager).to receive(:recompute_course).with(@course, assignments: anything, update_grades: true).at_least(:once)

      described_class.call(@course.id)
    end
  end
end
