#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "plugins ui" do
  include_context "in-process server selenium tests"

  before(:each) do
    site_admin_logged_in
  end

  it 'should have plugins default to disabled when no plugin_setting exits', priority: "1", test_id: 268053 do
    get '/plugins/etherpad'
    expect(is_checked('#plugin_setting_disabled')).to be_truthy

    multiple_accounts_select
    expect_new_page_load { submit_form("#new_plugin_setting") }
    expect(PluginSetting.all.map(&:name)).to eq(["etherpad"])
    PluginSetting.first.tap do |ps|
      expect(ps.name).to eq "etherpad"
      expect(ps.disabled).to be_truthy
    end
    get '/plugins/etherpad'
    expect(is_checked('#plugin_setting_disabled')).to be_truthy
  end

  it 'should have plugin settings not disabled when set', priority: "1", test_id: 268054 do
    get '/plugins/etherpad'
    expect(is_checked('#plugin_setting_disabled')).to be_truthy
    multiple_accounts_select
    f('#plugin_setting_disabled').click
    expect_new_page_load { submit_form("#new_plugin_setting") }
    expect(PluginSetting.all.map(&:name)).to eq(["etherpad"])
    PluginSetting.first.tap do |ps|
      expect(ps.name).to eq "etherpad"
      expect(ps.disabled).to be_falsey
    end
    get '/plugins/etherpad'

    multiple_accounts_select
    expect(is_checked('#plugin_setting_disabled')).to be_falsey
  end

  it "should not overwrite settings that are not shown" do
    get '/plugins/etherpad'

    multiple_accounts_select
    f("#plugin_setting_disabled").click
    expect_new_page_load { submit_form("#new_plugin_setting") }

    plugin_setting = PluginSetting.last
    plugin_setting.settings["other_thingy"] = "dude"
    plugin_setting.save!

    expect_new_page_load { submit_form("#edit_plugin_setting_#{plugin_setting.id}") }

    plugin_setting.reload
    expect(plugin_setting.settings["other_thingy"]).to eq "dude"
  end

  def multiple_accounts_select
    if !f("#plugin_setting_disabled").displayed?
      f("#accounts_select option:nth-child(2)").click
      expect(f("#plugin_setting_disabled")).to be_displayed
    end
    if !f(".save_button").enabled?
      f(".copy_settings_button").click
    end
  end
end

