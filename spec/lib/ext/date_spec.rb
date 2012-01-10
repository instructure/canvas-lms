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
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Date#in_time_zone" do
  before do
    @zones = ['America/Juneau', 'America/Denver', 'UTC', 'Asia/Baghdad', 'Asia/Shanghai'].map { |tzname| ActiveSupport::TimeZone.new(tzname) }
    @today = Time.zone.today
  end

  it "should give midnight regardless of time zone" do
    @zones.each do |tz|
      today_in_tz = @today.in_time_zone(tz.name)
      today_in_tz.hour.should       == 0
      today_in_tz.min.should        == 0
      today_in_tz.sec.should        == 0
      today_in_tz.utc_offset.should == tz.utc_offset
    end
  end

  it "should give the same date regardless of time zone" do
    @zones.each do |tz|
      today_in_tz = @today.in_time_zone(tz.name)
      today_in_tz.year.should       == @today.year
      today_in_tz.month.should      == @today.month
      today_in_tz.day.should        == @today.day
      today_in_tz.utc_offset.should == tz.utc_offset
    end
  end

  it "should work with no explicit zone given" do
    tz = @zones.first
    Time.use_zone(tz) do
      today_in_tz = @today.in_time_zone
      today_in_tz.hour.should       == 0
      today_in_tz.min.should        == 0
      today_in_tz.sec.should        == 0
      today_in_tz.utc_offset.should == tz.utc_offset
    end
  end
end
