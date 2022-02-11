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

describe PacePlanHardEndDateCompressor do
  before :once do
    course_with_student active_all: true
    @course.update start_at: "2021-09-01"
    @pace_plan = @course.pace_plans.create! workflow_state: "active", end_date: "2021-09-10"
    @module = @course.context_modules.create!
  end

  describe ".compress" do
    context "compresses dates to fit within the end date" do
      before :once do
        assignment = @course.assignments.create!
        assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
        @pace_plan.pace_plan_module_items.last.update! duration: 10
        assignment = @course.assignments.create!
        assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
        @pace_plan.pace_plan_module_items.last.update! duration: 0
        assignment = @course.assignments.create!
        assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
        @pace_plan.pace_plan_module_items.last.update! duration: 6
      end

      it "compresses the plan items by the required percentage to reach the hard end date" do
        compressed = PacePlanHardEndDateCompressor.compress(@pace_plan, @pace_plan.pace_plan_module_items)
        expect(compressed.pluck(:duration)).to eq([5, 0, 2])
      end

      it "does nothing if the duration of the pace plan is within the end date" do
        @pace_plan.update(end_date: "2022-09-10")
        compressed = PacePlanHardEndDateCompressor.compress(@pace_plan, @pace_plan.pace_plan_module_items)
        expect(compressed.pluck(:duration)).to eq([10, 0, 6])
      end

      it "compresses to end on the hard end date" do
        @course.update(start_at: "2021-12-27")
        @pace_plan.update(end_date: "2021-12-31", exclude_weekends: true, hard_end_dates: true)
        @pace_plan.pace_plan_module_items.each_with_index do |item, index|
          item.update(duration: (index + 1) * 2)
        end
        compressed = PacePlanHardEndDateCompressor.compress(@pace_plan, @pace_plan.pace_plan_module_items)
        expect(compressed.pluck(:duration)).to eq([1, 1, 2])
      end

      context "implicit end dates" do
        before :once do
          @course.update(start_at: "2021-12-27")
          @pace_plan.update(end_date: nil, exclude_weekends: true)
          @pace_plan.pace_plan_module_items.each_with_index do |item, index|
            item.update(duration: (index + 1) * 2)
          end
        end

        it "supports implicit end dates from the course's term" do
          @course.enrollment_term.update(end_at: "2021-12-31")
          compressed = PacePlanHardEndDateCompressor.compress(@pace_plan, @pace_plan.pace_plan_module_items)
          expect(compressed.pluck(:duration)).to eq([1, 1, 2])
        end

        it "supports implicit end dates from the course" do
          @course.update(conclude_at: "2021-12-31")
          compressed = PacePlanHardEndDateCompressor.compress(@pace_plan, @pace_plan.pace_plan_module_items)
          expect(compressed.pluck(:duration)).to eq([1, 1, 2])
        end
      end
    end

    it "paces assignments appropriately if there are too many" do
      20.times do |_i|
        assignment = @course.assignments.create!
        assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
      end
      @pace_plan.pace_plan_module_items.update(duration: 1)
      compressed = PacePlanHardEndDateCompressor.compress(@pace_plan, @pace_plan.pace_plan_module_items)
      expect(compressed.pluck(:duration)).to eq([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0])
    end
  end

  describe ".round_durations" do
    context "duration is >= 1" do
      context "the remainder is greater than the breakpoint" do
        it "rounds up if doing so would not cause an overallocation" do
          rounded = PacePlanHardEndDateCompressor.round_durations([7.8], 78)
          expect(rounded.map(&:duration)).to eq([8])
        end

        it "rounds down if rounding up would cause an overallocation" do
          rounded = PacePlanHardEndDateCompressor.round_durations([7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8], 78)
          expect(rounded.map(&:duration)).to eq([8, 8, 8, 8, 8, 8, 8, 8, 7, 7])
        end
      end

      context "the remainder is less than the breakpoint" do
        it "rounds down" do
          rounded = PacePlanHardEndDateCompressor.round_durations([2.5], 2)
          expect(rounded.map(&:duration)).to eq([2])
        end
      end
    end

    context "duration is < 1" do
      it "does calculates the groups based off their remainders" do
        rounded = PacePlanHardEndDateCompressor.round_durations([0.2, 0.2, 0.1, 0.2, 0.2, 0.5, 0.5, 0.5, 0.5, 0.5], 3)
        expect(rounded.map(&:duration)).to eq([1, 0, 0, 0, 0, 1, 0, 1, 0, 0])
      end
    end
  end

  describe ".shift_durations_down" do
    context "all days over can be absorbed by last item" do
      it "decreases last item duration by the number of days over" do
        rounded = PacePlanHardEndDateCompressor.shift_durations_down([Duration.new(5), Duration.new(5), Duration.new(5)], 3)
        expect(rounded.map(&:duration)).to eq([5, 5, 2])
      end
    end

    context "number of days over is greater than last item duration" do
      it "decreases last and subsequent item durations" do
        rounded = PacePlanHardEndDateCompressor.shift_durations_down([Duration.new(1), Duration.new(1), Duration.new(1)], 2)
        expect(rounded.map(&:duration)).to eq([1, 0, 0])
      end
    end

    context "number of days over is greater than the sum of durations" do
      it "decreases all durations to 0" do
        rounded = PacePlanHardEndDateCompressor.shift_durations_down([Duration.new(1), Duration.new(1), Duration.new(1)], 5)
        expect(rounded.map(&:duration)).to eq([0, 0, 0])
      end
    end
  end
end
