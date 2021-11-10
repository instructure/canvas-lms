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

require_relative 'course_copy_helper'

describe ContentMigration do
  context "pace plans" do
    include_examples "course copy"

    it "copies pace plan attributes" do
      pace_plan = @copy_from.pace_plans.new
      pace_plan.workflow_state = 'active'
      pace_plan.end_date = 1.day.from_now.beginning_of_day
      pace_plan.published_at = Time.now.utc
      pace_plan.exclude_weekends = false
      pace_plan.hard_end_dates = true
      pace_plan.save!

      run_course_copy
      expect(@copy_to.pace_plans.count).to eq 1

      pace_plan_to = @copy_to.pace_plans.take

      expect(pace_plan_to.workflow_state).to eq 'active'
      expect(pace_plan_to.start_date).to eq pace_plan.start_date
      expect(pace_plan_to.end_date).to eq pace_plan.end_date
      expect(pace_plan_to.published_at.to_i).to eq pace_plan.published_at.to_i
      expect(pace_plan_to.exclude_weekends).to eq false
      expect(pace_plan_to.hard_end_dates).to eq true
    end

    context "module items" do
      before :once do
        @a1 = @copy_from.assignments.create! name: 'a1'
        @a2 = @copy_from.assignments.create! name: 'a2'
        @mod1 = @copy_from.context_modules.create! name: 'module1'
        @tag1 = @mod1.add_item(type: 'assignment', id: @a1.id)
        @mod2 = @copy_from.context_modules.create! name: 'module2'
        @tag2 = @mod2.add_item(type: 'assignment', id: @a2.id)

        @pace_plan = @copy_from.pace_plans.create!
        @pace_plan.pace_plan_module_items.create! duration: 1, module_item_id: @tag1.id
        @pace_plan.pace_plan_module_items.create! duration: 2, module_item_id: @tag2.id
      end

      it "copies pace plan module item durations" do
        run_course_copy

        tag1_to = @copy_to.context_module_tags.where(migration_id: mig_id(@tag1)).take
        tag2_to = @copy_to.context_module_tags.where(migration_id: mig_id(@tag2)).take
        pace_plan_to = @copy_to.pace_plans.where(workflow_state: 'unpublished').take

        expect(pace_plan_to.pace_plan_module_items.find_by(module_item_id: tag1_to.id).duration).to eq 1
        expect(pace_plan_to.pace_plan_module_items.find_by(module_item_id: tag2_to.id).duration).to eq 2
      end

      it "copies a subset of module items in selective migrations" do
        @cm.copy_options = {
          all_pace_plans: true,
          context_modules: { mig_id(@mod1) => true }
        }
        run_course_copy

        pace_plan_to = @copy_to.pace_plans.where(workflow_state: 'unpublished').take
        expect(pace_plan_to.pace_plan_module_items.count).to eq 1
      end
    end
  end
end
