# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")

describe GradingPeriodHelper do
  describe ".date_in_closed_grading_period?" do
    let(:period_1) do
      GradingPeriod.new(
        title: "Closed Grading Period",
        start_date: 5.weeks.ago,
        end_date: 3.weeks.ago,
        close_date: 1.week.ago
      )
    end
    let(:period_2) do
      GradingPeriod.new(
        title: "Open Grading Period",
        start_date: 14.days.ago,
        end_date: 7.days.ago,
        close_date: 7.days.from_now
      )
    end
    let(:all_periods) { [period_1, period_2] }

    it "returns true when the date is within a closed grading period" do
      expect(GradingPeriodHelper.date_in_closed_grading_period?(4.weeks.ago, all_periods)).to eql(true)
    end

    it "returns false when the date is within an open grading period" do
      expect(GradingPeriodHelper.date_in_closed_grading_period?(10.days.ago, all_periods)).to eql(false)
    end

    it "returns false when the date is outside of all grading periods" do
      expect(GradingPeriodHelper.date_in_closed_grading_period?(6.weeks.ago, all_periods)).to eql(false)
      expect(GradingPeriodHelper.date_in_closed_grading_period?(15.days.ago, all_periods)).to eql(false)
      expect(GradingPeriodHelper.date_in_closed_grading_period?(Time.zone.today, all_periods)).to eql(false)
      expect(GradingPeriodHelper.date_in_closed_grading_period?(8.days.from_now, all_periods)).to eql(false)
    end

    it "returns true when the date is nil and the last grading period (by end_date) is closed" do
      expect(GradingPeriodHelper.date_in_closed_grading_period?(nil, [period_1])).to eql(true)
      period_2.close_date = 1.day.ago
      expect(GradingPeriodHelper.date_in_closed_grading_period?(nil, all_periods)).to eql(true)
    end

    it "returns false when the date is nil and the last grading period (by end_date) is not closed" do
      expect(GradingPeriodHelper.date_in_closed_grading_period?(nil, [period_2])).to eql(false)
      expect(GradingPeriodHelper.date_in_closed_grading_period?(nil, all_periods)).to eql(false)
      period_1.close_date = 7.days.from_now
      expect(GradingPeriodHelper.date_in_closed_grading_period?(nil, all_periods)).to eql(false)
    end

    it "returns false when passed no grading periods" do
      expect(GradingPeriodHelper.date_in_closed_grading_period?(Time.zone.today, [])).to eql(false)
    end
  end
end
