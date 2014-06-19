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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'HostUrl' do
  describe "protocol" do
    it "should return https if domain config says ssl" do
      ConfigFile.expects(:load).with("domain").returns({})
      Attachment.stubs(:file_store_config).returns({})
      HostUrl.protocol.should == 'http'
      HostUrl.reset_cache!
      ConfigFile.expects(:load).with("domain").returns('ssl' => true)
      HostUrl.protocol.should == 'https'
    end

    it "should return https if file store config says secure" do
      ConfigFile.stubs(:load).with("domain").returns({})
      Attachment.stubs(:file_store_config).returns('secure' => true)
      HostUrl.protocol.should == 'https'
    end

    it "should return https for production" do
      HostUrl.protocol.should == 'http'
      HostUrl.reset_cache!
      Rails.env.expects(:production?).returns(true)
      HostUrl.protocol.should == 'https'
    end
  end
end
