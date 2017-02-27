#
# Copyright (C) 2015 Instructure, Inc.
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

describe Setting do

  context "getting" do

    it 'should get the default value as a string' do
      expect(Setting.get('my_new_setting', true)).to eq 'true'
    end

    it 'should get the default value as a string for dates' do
      time = Time.now.utc
      expect(Setting.get('my_new_setting', time)).to eq time.to_s
    end

    it 'should return set values' do
      Setting.set('my_new_setting', '1')
      expect(Setting.get('my_new_setting', '0')).to eq '1'
    end
  end

  context "setting" do

    it 'should set values as strings' do
      Setting.set('my_new_setting', true)
      expect(Setting.get('my_new_setting', '1')).to eq 'true'
    end

    it 'should set values as strings' do
      time = Time.now.utc
      Setting.set('my_new_setting', time)
      expect(Setting.get('my_new_setting', '1')).to eq time.to_s
    end
  end

end
