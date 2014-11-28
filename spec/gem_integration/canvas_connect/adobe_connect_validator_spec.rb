#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Canvas::Plugins::Validators::AdobeConnectValidator do
  let(:plugin_setting) { mock }

  subject { Canvas::Plugins::Validators::AdobeConnectValidator }

  it 'should allow an empty hash' do
    expect(subject.validate({}, plugin_setting)).to eql Hash.new
  end

  it 'should error on missing keys' do
    plugin_setting.expects(:errors).returns(stub(:add_to_base => true))
    expect(subject.validate({:domain => 'example.com'}, plugin_setting)).to be_falsey
  end

  it 'should pass if all keys exist' do
    valid_keys = {
      :domain => 'example.com',
      :login => 'username',
      :password => 'password',
      :meeting_container => 'folder_name',
      :use_sis_ids => true
    }

    expect(subject.validate(valid_keys, plugin_setting)).to eql valid_keys
  end
end
