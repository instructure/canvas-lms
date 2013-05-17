#
# Copyright (C) 2013 Instructure, Inc.
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

if RUBY_VERSION >= "1.9"
describe 'Time Marshal override' do
  it "should preserve the old marshalling for post-1900 dates" do
    raw_time = Time.zone.parse('2013-02-16 05:43:21.15Z').time
    dumped = Marshal.dump(raw_time)
    dumped.should == "\x04\bu:\tTime\r\x05F\x1C\xC0\xF0IR\xAD"
    reloaded = Marshal.load(dumped)
    reloaded.should == raw_time
  end

  it "should not fail for pre-1900 dates" do
    old_time = Time.zone.parse('0010-05-13 04:12:51Z')
    raw_time = old_time.time
    dumped = Marshal.dump(raw_time)
    dumped.should == "\x04\bIu:\tTime!pre1900:0010-05-13T04:12:51Z\x06:\x06EF"
    reloaded = Marshal.load(dumped)
    reloaded.should == raw_time
    # confirm it works for TimeWithZone as well
    Marshal.load(Marshal.dump(old_time)).should == old_time
  end
end
end # RUBY_VERSION
