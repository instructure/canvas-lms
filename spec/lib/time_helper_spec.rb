# encoding: UTF-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe TimeHelper do
  describe '.try_parse' do
    it 'converts a string into a time' do
      parsed_time = Time.zone.parse('2012-12-12 12:12:12 -0600')
      TimeHelper.try_parse('2012-12-12 12:12:12 -0600').should == parsed_time
    end

    it 'uses Time.zone.parse for proper timezone handling' do
      parsed_time = Time.zone.parse('2012-12-12 12:12:12')
      TimeHelper.try_parse('2012-12-12 12:12:12').should == parsed_time
    end

    it 'returns nil when no default is provided and time does not parse' do
      TimeHelper.try_parse('NOT A TIME').should be_nil
      TimeHelper.try_parse('-45-45-45 12:12:12').should be_nil
    end

    it 'returns the provided default if it is provided and the time does not parse' do
      TimeHelper.try_parse('NOT A TIME', :default).should == :default
      TimeHelper.try_parse('-45-45-45 12:12:12', :default).should == :default
    end
  end
end
