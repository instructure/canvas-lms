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

describe BlackoutDate do
  context "associations" do
    it "has functioning course context association" do
      course_factory
      bd = @course.blackout_dates.create! start_date: 1.day.from_now, end_date: 1.week.from_now, event_title: 'foo'
      expect(bd.context).to eq @course
      expect(bd.root_account).to eq @course.root_account
    end

    it "has functioning account context association" do
      bd = Account.default.blackout_dates.create! start_date: 1.day.from_now, end_date: 1.week.from_now, event_title: 'baz'
      expect(bd.context).to eq Account.default
      expect(bd.root_account).to eq Account.default
    end
  end

  context "validations" do
    it "requires end_date to be greater than or equal to start_date" do
      bd = Account.default.blackout_dates.build start_date: 1.day.from_now, end_date: 1.day.ago, event_title: 'time warp'
      expect(bd).not_to be_valid
      expect(bd.errors.to_a).to eq(["End date can't be before start date"])
    end
  end
end
