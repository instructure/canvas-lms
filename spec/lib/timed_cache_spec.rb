#
# Copyright (C) 2014 Instructure, Inc.
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

describe "TimedCache" do
  it "should expire the cache if older than specified" do
    cleared = 0
    Timecop.freeze do
      cache = TimedCache.new(-> { 60.seconds.ago }) do
        cleared += 1
      end

      cache.clear.should == false
      cleared.should == 0

      Timecop.travel(70.seconds)

      cache.clear.should == true
      cleared.should == 1
    end
  end
end

