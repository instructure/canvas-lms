# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
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

require_relative '../../spec_helper'

module Utils
  describe DatetimeRangePresenter do
    describe "#as_string" do
      it 'can display a single datetime if theres no range' do
        datetime = Time.zone.parse("#{Time.zone.now.year}-01-01 12:00:00")
        presenter = DatetimeRangePresenter.new(datetime)
        expect(presenter.as_string).to eq("Jan 1 at 12pm")
      end

      describe "with shortened midnight" do
        before { Timecop.travel(Time.utc(2014, 10, 1, 9, 30)) }
        after { Timecop.return }

        it "omits the time for events when midnight is specified as shortened" do
          datetime = Time.zone.now.midnight
          presenter = DatetimeRangePresenter.new(datetime)
          expect(presenter.as_string(shorten_midnight: true)).to eq("Oct 1")
        end

        it "omits the time for due dates when midnight is shortened" do
          datetime = Time.zone.now.midnight - 1.minute
          presenter = DatetimeRangePresenter.new(datetime, nil, :due_date)
          expect(presenter.as_string(shorten_midnight: true)).to eq("Sep 30")
        end
      end

      it "ignores ranges for due dates" do
        datetime = Time.zone.parse("#{Time.now.year}-01-01 12:00:00")
        endtime = datetime + 1.hour
        presenter = DatetimeRangePresenter.new(datetime, endtime, :due_date)
        expect(presenter.as_string).to eq("Jan 1 by 12pm")
      end

      it 'handles ranges' do
        datetime = Time.zone.parse("#{Time.now.year}-01-01 12:00:00")
        end_datetime = datetime + 2.days
        presenter = DatetimeRangePresenter.new(datetime, end_datetime)
        expect(presenter.as_string).to eq("Jan 1 at 12pm to Jan 3 at 12pm")
      end

      it "omits second date if start and end are on the same day" do
        datetime = Time.zone.parse("#{Time.zone.now.year}-01-01 12:00:00")
        end_datetime = datetime.advance(hours: 1)
        presenter = DatetimeRangePresenter.new(datetime, end_datetime)
        expect(presenter.as_string).to eq("Jan 1 from 12pm to  1pm")
      end

      it "should include the year if the current year isn't the same" do
        Timecop.travel(Time.utc(2014, 10, 1, 9, 30))
        nextyear = Time.zone.now.advance(years: 1)
        presenter = DatetimeRangePresenter.new(nextyear)
        expect(presenter.as_string).to eq("Oct 1, 2015 at  9:30am")
        Timecop.return
      end

      it "accepts a timezone override" do
        datetime = Time.zone.parse("#{Time.zone.now.year}-01-01 12:00:00")
        mountain_presenter = DatetimeRangePresenter.new(datetime, nil, :event, ActiveSupport::TimeZone["America/Denver"])
        central_presenter = DatetimeRangePresenter.new(datetime, nil, :event, ActiveSupport::TimeZone["America/Chicago"])
        expect(mountain_presenter.as_string).to eq("Jan 1 at  5am")
        expect(central_presenter.as_string).to eq("Jan 1 at  6am")
      end

      it "can deal with date boundaries in the override on time objects" do
        pre_zone = Time.zone
        Time.zone = "Alaska"
        Timecop.freeze(Time.utc(2014,10,1,7,30))
        datetime = Time.now

        alaskan_presenter = DatetimeRangePresenter.new(datetime)
        mountain_presenter = DatetimeRangePresenter.new(datetime, nil, :event,  ActiveSupport::TimeZone["America/Denver"])
        expect(alaskan_presenter.as_string).to eq("Sep 30 at 11:30pm")
        expect(mountain_presenter.as_string).to eq("Oct 1 at  1:30am")
        Timecop.return
        Time.zone = pre_zone
      end

    end
  end
end
