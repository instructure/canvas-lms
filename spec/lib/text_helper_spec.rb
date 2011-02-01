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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

class TestClassForMixins
  include TextHelper
end

describe TextHelper do

  context "datetime_string" do

    it "should include the year if the current year isn't the same" do
      today = ActiveSupport::TimeWithZone.new(Time.now, Time.zone)
      nextyear = today + 1.year
      datestring = TestClassForMixins.new.datetime_string nextyear
      datestring.split[2].to_i.should == nextyear.year
      TestClassForMixins.new.datetime_string(today).split.size.should == (datestring.split.size - 1)
    end

  end

  context "date_string" do

    it "should include the year if the current year isn't the same" do
      today = ActiveSupport::TimeWithZone.new(Time.now, Time.zone)
      # cause we don't want to deal with day-of-the-week stuff, offset 8 days
      if today.year == (today + 8.days).year
        today += 8.days
      else
        today -= 8.days
      end
      nextyear = today + 1.year
      datestring = TestClassForMixins.new.date_string nextyear
      datestring.split[2].to_i.should == nextyear.year
      TestClassForMixins.new.date_string(today).split.size.should == (datestring.split.size - 1)
    end

    it "should not say the day of the week if it's exactly a few years away" do
      aday = ActiveSupport::TimeWithZone.new(Time.now, Time.zone) + 2.days
      nextyear = aday + 1.year
      TestClassForMixins.new.date_string(aday).should == aday.strftime("%A")
      TestClassForMixins.new.date_string(nextyear).should_not == nextyear.strftime("%A")
      # in fact,
      TestClassForMixins.new.date_string(nextyear).split[2].to_i.should == nextyear.year
    end

  end

end
