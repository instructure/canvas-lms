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

require 'spec_helper'

describe Diigo::Connection do
  describe ".config_check" do
    it "returns nil if there are no config issues" do
      config = {
        api_key: 'key'
      }
      Diigo::Connection.config = Proc.new do
        config
      end
      response = Diigo::Connection.config_check(config)
      expect(response).to eq nil
    end

    it "returns error if there are config issues" do
      config = {
        api_key: nil
      }
      Diigo::Connection.config = Proc.new do
        config
      end
      response = Diigo::Connection.config_check(config)
      expect(response).to eq "Configuration check failed, please check your settings"
    end
  end
end
