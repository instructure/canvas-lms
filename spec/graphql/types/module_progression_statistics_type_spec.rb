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

require_relative "../graphql_spec_helper"

describe Types::ModuleProgressionStatisticsType do
  before(:once) do
    course_with_student(active_all: true)

    @module1 = @course.context_modules.create!(name: "Module 1")
    @module2 = @course.context_modules.create!(name: "Module 2")
    @module3 = @course.context_modules.create!(name: "Module 3")

    @progression1 = @module1.context_module_progressions.create!(
      user: @student,
      workflow_state: "completed",
      current: true,
      evaluated_at: 1.hour.ago
    )
    @progression2 = @module2.context_module_progressions.create!(
      user: @student,
      workflow_state: "started",
      current: true,
      evaluated_at: 1.hour.ago
    )
    @progression3 = @module3.context_module_progressions.create!(
      user: @student,
      workflow_state: "locked",
      current: true,
      evaluated_at: 1.hour.ago
    )
  end

  let(:course_type) { GraphQLTypeTester.new(@course, current_user: @student) }

  describe "completed_modules_count" do
    it "counts completed module progressions" do
      expect(course_type.resolve("moduleProgressionStatistics { completedModulesCount }")).to eq 1
    end

    it "returns nil when current_user is nil" do
      course_type_no_user = GraphQLTypeTester.new(@course, current_user: nil)
      expect(course_type_no_user.resolve("moduleProgressionStatistics { completedModulesCount }")).to be_nil
    end
  end

  describe "total_modules_count" do
    it "counts all module progressions" do
      expect(course_type.resolve("moduleProgressionStatistics { totalModulesCount }")).to eq 3
    end

    it "returns nil when current_user is nil" do
      course_type_no_user = GraphQLTypeTester.new(@course, current_user: nil)
      expect(course_type_no_user.resolve("moduleProgressionStatistics { totalModulesCount }")).to be_nil
    end
  end

  describe "in_progress_modules_count" do
    it "counts started module progressions" do
      expect(course_type.resolve("moduleProgressionStatistics { inProgressModulesCount }")).to eq 1
    end

    it "returns nil when current_user is nil" do
      course_type_no_user = GraphQLTypeTester.new(@course, current_user: nil)
      expect(course_type_no_user.resolve("moduleProgressionStatistics { inProgressModulesCount }")).to be_nil
    end
  end

  describe "locked_modules_count" do
    it "counts locked module progressions" do
      expect(course_type.resolve("moduleProgressionStatistics { lockedModulesCount }")).to eq 1
    end

    it "returns nil when current_user is nil" do
      course_type_no_user = GraphQLTypeTester.new(@course, current_user: nil)
      expect(course_type_no_user.resolve("moduleProgressionStatistics { lockedModulesCount }")).to be_nil
    end
  end

  describe "various progression states" do
    before(:once) do
      @module4 = @course.context_modules.create!(name: "Module 4")
      @progression4 = @module4.context_module_progressions.create!(
        user: @student,
        workflow_state: "unlocked",
        current: true,
        evaluated_at: 1.hour.ago
      )
    end

    it "handles all workflow states" do
      expect(course_type.resolve("moduleProgressionStatistics { completedModulesCount }")).to eq 1
      expect(course_type.resolve("moduleProgressionStatistics { totalModulesCount }")).to eq 4
      expect(course_type.resolve("moduleProgressionStatistics { inProgressModulesCount }")).to eq 1
      expect(course_type.resolve("moduleProgressionStatistics { lockedModulesCount }")).to eq 1
    end
  end

  describe "edge cases" do
    it "handles user with no module progressions" do
      new_student = user_factory(active_all: true)
      @course.enroll_student(new_student, enrollment_state: "active")
      new_course_type = GraphQLTypeTester.new(@course, current_user: new_student)

      expect(new_course_type.resolve("moduleProgressionStatistics { completedModulesCount }")).to eq 0
      expect(new_course_type.resolve("moduleProgressionStatistics { totalModulesCount }")).to eq 0
      expect(new_course_type.resolve("moduleProgressionStatistics { inProgressModulesCount }")).to eq 0
      expect(new_course_type.resolve("moduleProgressionStatistics { lockedModulesCount }")).to eq 0
    end

    it "excludes progressions that have not been evaluated" do
      @module5 = @course.context_modules.create!(name: "Module 5")
      @progression5 = @module5.context_module_progressions.create!(
        user: @student,
        workflow_state: "locked",
        current: false,
        evaluated_at: nil
      )

      expect(course_type.resolve("moduleProgressionStatistics { totalModulesCount }")).to eq 3
      expect(course_type.resolve("moduleProgressionStatistics { lockedModulesCount }")).to eq 1
    end

    it "excludes stale progressions (current=false, evaluated_at=nil)" do
      @progression3.update!(current: false, evaluated_at: nil)

      expect(course_type.resolve("moduleProgressionStatistics { totalModulesCount }")).to eq 2
      expect(course_type.resolve("moduleProgressionStatistics { lockedModulesCount }")).to eq 0
    end

    it "includes progressions that were evaluated but are now outdated" do
      @progression3.update!(current: false, evaluated_at: 1.day.ago)

      expect(course_type.resolve("moduleProgressionStatistics { totalModulesCount }")).to eq 3
      expect(course_type.resolve("moduleProgressionStatistics { lockedModulesCount }")).to eq 1
    end

    it "includes progressions that are current" do
      @progression1.update!(current: true, evaluated_at: 1.hour.ago)
      @progression2.update!(current: true, evaluated_at: 1.hour.ago)
      @progression3.update!(current: true, evaluated_at: 1.hour.ago)

      expect(course_type.resolve("moduleProgressionStatistics { totalModulesCount }")).to eq 3
      expect(course_type.resolve("moduleProgressionStatistics { completedModulesCount }")).to eq 1
      expect(course_type.resolve("moduleProgressionStatistics { inProgressModulesCount }")).to eq 1
      expect(course_type.resolve("moduleProgressionStatistics { lockedModulesCount }")).to eq 1
    end
  end
end
