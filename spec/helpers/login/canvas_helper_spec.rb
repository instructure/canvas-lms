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

require_relative '../../spec_helper'

describe Login::CanvasHelper do
  describe "#session_timeout_enabled" do
    context "when the sessions plugin is enabled" do 
      before do 
        PluginSetting.expects(:settings_for_plugin).with('sessions').returns({"session_timeout" => 123})
      end

      it "returns true" do
        expect(helper.session_timeout_enabled?).to be_truthy
      end
    end

    context "when the sessions plugin is disabled" do 
      before do 
        PluginSetting.expects(:settings_for_plugin).with('sessions').returns(nil)
      end

      it "returns false" do 
        expect(helper.session_timeout_enabled?).to be_falsey
      end
    end
  end
end
