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

require "active_support/testing/time_helpers"

describe CoursePaceHardEndDateCompressor do
  include ActiveSupport::Testing::TimeHelpers
  before :once do
    course_with_student active_all: true
    @course.update start_at: "2021-09-01", restrict_enrollments_to_course_dates: true
    @course.enable_course_paces = true
    @course.save!
    @course_pace = @course.course_paces.create!(
      workflow_state: "active",
      end_date: "2021-09-10",
      hard_end_dates: true,
      published_at: Time.zone.now
    )
    @module = @course.context_modules.create!
  end

  describe ".compress" do
    context "compresses dates to fit within the end date" do
      before :once do
        assignment = @course.assignments.create!
        assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
        @course_pace.course_pace_module_items.last.update! duration: 10
        assignment = @course.assignments.create!
        assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
        @course_pace.course_pace_module_items.last.update! duration: 0
        assignment = @course.assignments.create!
        assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
        @course_pace.course_pace_module_items.last.update! duration: 6
      end

      context "when add_selected_days_to_skip_param is enabled" do
        before do
          @course.root_account.enable_feature!(:course_paces_skip_selected_days)
          @course_pace.update selected_days_to_skip: %w[sat sun]
          @course_pace.course.root_account.reload
        end

        it "compresses the plan items by the required percentage to reach the hard end date" do
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([5, 0, 2])
        end

        it "does nothing if the duration of the course pace is within the end date" do
          @course_pace.update(end_date: "2022-09-10")
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([10, 0, 6])
        end

        it "compresses to end on the hard end date" do
          travel_to Time.zone.local(2021, 12, 27) do
            @course.update!(start_at: Time.zone.today)
            @course_pace.update!(
              end_date: "2021-12-31",
              hard_end_dates: true,
              exclude_weekends: true
            )

            durations = [2, 4, 6]
            @course_pace.course_pace_module_items.order(:id).each_with_index do |item, index|
              item.update!(duration: durations[index])
            end

            items = @course_pace.course_pace_module_items.order(:id).map(&:reload)
            compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, items)

            expect(compressed.map(&:duration)).to eq([1, 1, 2])
          end
        end

        it "respects course blackout dates" do
          @course.blackout_dates.create!(event_title: "Blackout Test", start_date: "2021-09-01", end_date: "2021-09-01")
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([4, 0, 2])
        end

        it "respects account blackout dates" do
          @course.account.calendar_events.create!(title: "Blackout Test", start_at: "2021-09-01", end_at: "2021-09-01", blackout_date: true)
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([4, 0, 2])
        end
      end

      context "when add_selected_days_to_skip_param is disabled" do
        before do
          @course.root_account.disable_feature!(:course_paces_skip_selected_days)
          @course_pace.update exclude_weekends: true
          @course_pace.course.root_account.reload
        end

        it "compresses the plan items by the required percentage to reach the hard end date" do
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([5, 0, 2])
        end

        it "does nothing if the duration of the course pace is within the end date" do
          @course_pace.update(end_date: "2022-09-10")
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([10, 0, 6])
        end

        it "compresses to end on the hard end date" do
          travel_to Time.zone.local(2021, 12, 27) do
            @course.update!(start_at: Time.zone.today)
            @course_pace.update!(end_date: "2021-12-31", hard_end_dates: true)

            durations = [2, 4, 6]
            @course_pace.course_pace_module_items.order(:id).each_with_index do |item, index|
              item.update!(duration: durations[index])
            end

            items = @course_pace.course_pace_module_items.order(:id).map(&:reload)
            compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, items)

            expect(compressed.map(&:duration)).to eq([1, 1, 2])
          end
        end

        it "respects course blackout dates" do
          @course.blackout_dates.create!(event_title: "Blackout Test", start_date: "2021-09-01", end_date: "2021-09-01")
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([4, 0, 2])
        end

        it "respects account blackout dates" do
          @course.account.calendar_events.create!(title: "Blackout Test", start_at: "2021-09-01", end_at: "2021-09-01", blackout_date: true)
          compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
          expect(compressed.pluck(:duration)).to eq([4, 0, 2])
        end
      end

      context "implicit end dates" do
        before :once do
          @course.update(start_at: "2021-12-27")
          @course_pace.update(end_date: nil, hard_end_dates: false)
          durations = [2, 4, 6]
          @course_pace.course_pace_module_items.order(:id).each_with_index do |item, index|
            item.update!(duration: durations[index])
          end
        end

        context "when add_selected_days_to_skip_param is enabled" do
          before do
            @course.root_account.enable_feature!(:course_paces_skip_selected_days)
            @course_pace.update selected_days_to_skip: %w[sat sun]
          end

          it "supports implicit end dates from the course's term" do
            travel_to Time.zone.local(2021, 12, 27) do
              @course.update(restrict_enrollments_to_course_dates: false)
              @course.enrollment_term.update(start_at: "2021-12-27", end_at: "2021-12-31")
              compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
              expect(compressed.pluck(:duration)).to eq([1, 1, 2])
            end
          end

          it "supports implicit end dates from the course" do
            travel_to Time.zone.local(2021, 12, 27) do
              @course.update(conclude_at: "2021-12-31")
              compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
              expect(compressed.pluck(:duration)).to eq([1, 1, 2])
            end
          end

          it "considers the end date the previous Friday if it falls on the weekend" do
            travel_to Time.zone.parse("2021-12-27") do
              @course.update(start_at: Time.zone.parse("2021-12-27"), conclude_at: Time.zone.parse("2022-01-02"))
              compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
              expect(compressed.pluck(:duration)).to eq([1, 1, 2])
            end
          end
        end

        context "when add_selected_days_to_skip_param is disabled" do
          let(:start_date) { Date.parse("2021-12-27") }
          let(:end_date) { Date.parse("2021-12-31") }

          before do
            travel_to(start_date) do
              @course.root_account.disable_feature!(:course_paces_skip_selected_days)
              @course_pace.update!(exclude_weekends: true)
            end
          end

          it "supports implicit end dates from the course's term" do
            travel_to(start_date) do
              @course.update!(restrict_enrollments_to_course_dates: false)
              @course.enrollment_term.update!(start_at: start_date, end_at: end_date)

              compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
              expect(compressed.pluck(:duration)).to eq([1, 1, 2])
            end
          end

          it "supports implicit end dates from the course" do
            travel_to(start_date) do
              @course.update!(conclude_at: end_date)

              compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
              expect(compressed.pluck(:duration)).to eq([1, 1, 2])
            end
          end

          it "considers the end date the previous Friday if it falls on the weekend" do
            travel_to(start_date) do
              @course.update!(conclude_at: "2022-01-02")
              compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
              expect(compressed.pluck(:duration)).to eq([1, 1, 2])
            end
          end
        end
      end
    end

    context "paces assignments appropriately if there are too many" do
      before do
        20.times do |_i|
          assignment = @course.assignments.create!
          assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
        end
      end

      it "add_selected_days_to_skip_param is enabled" do
        @course.root_account.enable_feature!(:course_paces_skip_selected_days)
        @course_pace.update selected_days_to_skip: %w[sat sun]

        @course_pace.course_pace_module_items.update(duration: 1)
        compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
        expect(compressed.pluck(:duration)).to eq([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0])
      end

      it "add_selected_days_to_skip_param is disabled" do
        @course.root_account.disable_feature!(:course_paces_skip_selected_days)
        @course_pace.update exclude_weekends: true

        @course_pace.course_pace_module_items.update(duration: 1)
        compressed = CoursePaceHardEndDateCompressor.compress(@course_pace, @course_pace.course_pace_module_items.order(:id))
        expect(compressed.pluck(:duration)).to eq([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0])
      end
    end
  end

  describe ".round_durations" do
    context "duration is >= 1" do
      context "the remainder is greater than the breakpoint" do
        it "rounds up if doing so would not cause an overallocation" do
          rounded = CoursePaceHardEndDateCompressor.round_durations([7.8], 78)
          expect(rounded.map(&:duration)).to eq([8])
        end

        it "rounds down if rounding up would cause an overallocation" do
          rounded = CoursePaceHardEndDateCompressor.round_durations([7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8], 78)
          expect(rounded.map(&:duration)).to eq([8, 8, 8, 8, 8, 8, 8, 8, 7, 7])
        end
      end

      context "the remainder is less than the breakpoint" do
        it "rounds down" do
          rounded = CoursePaceHardEndDateCompressor.round_durations([2.5], 2)
          expect(rounded.map(&:duration)).to eq([2])
        end
      end
    end

    context "duration is < 1" do
      it "does calculates the groups based off their remainders" do
        rounded = CoursePaceHardEndDateCompressor.round_durations([0.2, 0.2, 0.1, 0.2, 0.2, 0.5, 0.5, 0.5, 0.5, 0.5], 3)
        expect(rounded.map(&:duration)).to eq([1, 0, 0, 0, 0, 1, 0, 1, 0, 0])
      end
    end
  end

  describe ".shift_durations_down" do
    context "all days over can be absorbed by last item" do
      it "decreases last item duration by the number of days over" do
        rounded = CoursePaceHardEndDateCompressor.shift_durations_down([PaceDuration.new(5), PaceDuration.new(5), PaceDuration.new(5)], 3)
        expect(rounded.map(&:duration)).to eq([5, 5, 2])
      end
    end

    context "number of days over is greater than last item duration" do
      it "decreases last and subsequent item durations" do
        rounded = CoursePaceHardEndDateCompressor.shift_durations_down([PaceDuration.new(1), PaceDuration.new(1), PaceDuration.new(1)], 2)
        expect(rounded.map(&:duration)).to eq([1, 0, 0])
      end
    end

    context "number of days over is greater than the sum of durations" do
      it "decreases all durations to 0" do
        rounded = CoursePaceHardEndDateCompressor.shift_durations_down([PaceDuration.new(1), PaceDuration.new(1), PaceDuration.new(1)], 5)
        expect(rounded.map(&:duration)).to eq([0, 0, 0])
      end
    end
  end
end
