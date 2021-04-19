# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
      expect(ConfigFile).to receive(:load).with("domain").and_return({})
      allow(Attachment).to receive(:file_store_config).and_return({})
      expect(HostUrl.protocol).to eq 'http'
      HostUrl.reset_cache!
      expect(ConfigFile).to receive(:load).with("domain").and_return('ssl' => true)
      expect(HostUrl.protocol).to eq 'https'
    end

    it "should return https if file store config says secure" do
      allow(ConfigFile).to receive(:load).with("domain").and_return({})
      allow(Attachment).to receive(:file_store_config).and_return('secure' => true)
      expect(HostUrl.protocol).to eq 'https'
    end

    it "should return https for production" do
      expect(HostUrl.protocol).to eq 'http'
      HostUrl.reset_cache!
      expect(Rails.env).to receive(:production?).and_return(true)
      expect(HostUrl.protocol).to eq 'https'
    end
  end
end
