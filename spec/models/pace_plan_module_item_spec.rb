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

describe PacePlanModuleItem do
  before :once do
    course_with_student active_all: true

    @mod1 = @course.context_modules.create! name: 'M1'
    @a1 = @course.assignments.create! name: 'A1', workflow_state: 'unpublished'
    @mod1.add_item id: @a1.id, type: 'assignment'

    @mod2 = @course.context_modules.create! name: 'M2'
    @a2 = @course.assignments.create! name: 'A2', workflow_state: 'unpublished'
    @mod2.add_item id: @a2.id, type: 'assignment'
    @a3 = @course.assignments.create! name: 'A3', workflow_state: 'unpublished'
    @mod2.add_item id: @a3.id, type: 'assignment'

    @pace_plan = @course.pace_plans.create!
    @course.context_module_tags.each do |tag|
      @pace_plan.pace_plan_module_items.create! module_item: tag
    end
  end

  context "associations" do
    before :once do
      @item = @pace_plan.pace_plan_module_items.take
    end

    it "has a functioning pace_plan association" do
      expect(@item.pace_plan).to eq @pace_plan
    end

    it "has a functioning module_item association" do
      expect(@item.module_item.context_module.course).to eq @course
    end
  end

  context "scopes" do
    it "can filter on active module item status" do
      expect(@pace_plan.pace_plan_module_items.active).to be_empty
      @a3.publish!
      items = @pace_plan.pace_plan_module_items.active
      expect(items.size).to eq 1
      expect(items.first.module_item.content).to eq @a3
    end

    it "can order based on module progression order" do
      expect(@pace_plan.pace_plan_module_items.ordered.map { |item| item.module_item.content }).to eq([@a1, @a2, @a3])
    end
  end

  context "root_account_id" do
    it "infers root_account_id from pace_plan" do
      expect(@pace_plan.pace_plan_module_items.first.root_account).to eq @course.root_account
    end
  end
end
