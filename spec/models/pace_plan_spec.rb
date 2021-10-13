# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative '../spec_helper'

describe PacePlan do
  before :once do
    course_with_student active_all: true
    @module = @course.context_modules.create!
    @assignment = @course.assignments.create!
    @tag = @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: 'context_module'
    @pace_plan = @course.pace_plans.create! workflow_state: 'active'
    @pace_plan.pace_plan_module_items.create! module_item: @tag
  end

  context "associations" do
    it "has functioning course association" do
      expect(@course.pace_plans).to match_array([@pace_plan])
      expect(@pace_plan.course).to eq @course
    end

    it "has functioning pace_plan_module_items association" do
      expect(@pace_plan.pace_plan_module_items.map(&:module_item)).to match_array([@tag])
    end
  end

  context "scopes" do
    before :once do
      @other_section = @course.course_sections.create! name: 'other_section'
      @section_plan = @course.pace_plans.create! course_section: @other_section
      @student_plan = @course.pace_plans.create! user: @student
    end

    it "has a working primary scope" do
      expect(@course.pace_plans.primary).to match_array([@pace_plan])
    end

    it "has a working for_user scope" do
      expect(@course.pace_plans.for_user(@student)).to match_array([@student_plan])
    end

    it "has a working for_section scope" do
      expect(@course.pace_plans.for_section(@other_section)).to match_array([@section_plan])
    end
  end

  context "pace_plan_context" do
    it "requires a course" do
      bad_plan = PacePlan.create
      expect(bad_plan).not_to be_valid

      bad_plan.course = course_factory
      expect(bad_plan).to be_valid
    end

    it "disallows a user and section simultaneously" do
      course_with_student
      bad_plan = @course.pace_plans.build(user: @student, course_section: @course.default_section)
      expect(bad_plan).not_to be_valid

      bad_plan.course_section = nil
      expect(bad_plan).to be_valid
    end
  end

  context "constraints" do
    it "has a unique constraint on course for active primary pace plans" do
      expect { @course.pace_plans.create! workflow_state: 'active' }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "has a unique constraint for active section pace plans" do
      @course.pace_plans.create! course_section: @course.default_section, workflow_state: 'active'
      expect {
        @course.pace_plans.create! course_section: @course.default_section, workflow_state: 'active'
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "has a unique constraint for active student pace plans" do
      @course.pace_plans.create! user: @student, workflow_state: 'active'
      expect {
        @course.pace_plans.create! user: @student, workflow_state: 'active'
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "root_account" do
    it "infers root_account_id from course" do
      expect(@pace_plan.root_account).to eq @course.root_account
    end
  end

  context "duplicate" do
    it "returns a saved duplicate of the pace plan" do
      duplicate_pace_plan = @pace_plan.duplicate
      expect(duplicate_pace_plan.class).to eq(PacePlan)
      expect(duplicate_pace_plan.persisted?).to eq(true)
      expect(duplicate_pace_plan.id).not_to eq(@pace_plan.id)
    end

    it "supports passing in options" do
      opts = { user_id: 1 }
      duplicate_pace_plan = @pace_plan.duplicate(opts)
      expect(duplicate_pace_plan.user_id).to eq(opts[:user_id])
      expect(duplicate_pace_plan.course_section_id).to eq(opts[:course_section_id])
    end
  end
end
