#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "plugins/show" do
  it "renders without exploding" do
    plugin = stub(
      id: 'some_plugin',
      name: "Some Plugin",
      settings_partial: "settings_header"
    )
    plugin_setting = PluginSetting.new()

    assign(:plugin, plugin)
    assign(:plugin_setting, plugin_setting)
    view.stubs(:plugin_path).returns("/some/path")
    view.stubs(:params).returns({id: 'some_plugin'})
    render 'plugins/show'
    expect(response.body).to match("Return to plugins list")
  end
end
