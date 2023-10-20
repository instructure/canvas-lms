# frozen_string_literal: true

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

require_relative "../common"

# FOO-2994 all these tests have become flaky in the post-merge build for some
# reason that is difficult to suss out. For now, we'll skip them since what they
# are testing is only available to siteadmin anyway, but a decision should be
# made regarding fixing/improving them vs simply removing them altogether
describe.skip "default plugins FOO-2994" do
  include_context "in-process server selenium tests"

  before do
    user_logged_in
    Account.site_admin.account_users.create!(user: @user)
  end

  it "allows configuring twitter plugin" do
    settings = Canvas::Plugin.find(:twitter).try(:settings)
    expect(settings).to be_nil

    allow(Twitter::Connection).to receive(:config_check).and_return("Bad check")
    get "/plugins/twitter"

    multiple_accounts_select
    f("#plugin_setting_disabled").click
    wait_for_ajaximations
    f("#settings_consumer_key").send_keys("asdf")
    f("#settings_consumer_secret").send_keys("asdf")
    submit_form("#new_plugin_setting")

    assert_flash_error_message "There was an error"

    f("#settings_consumer_secret").send_keys("asdf")
    allow(Twitter::Connection).to receive(:config_check).and_return(nil)

    submit_form("#new_plugin_setting")
    wait_for_ajax_requests

    assert_flash_notice_message "successfully updated"

    settings = Canvas::Plugin.find(:twitter).try(:settings)
    expect(settings).not_to be_nil
    expect(settings[:consumer_key]).to eq "asdf"
    expect(settings[:consumer_secret_dec]).to eq "asdf"
  end

  it "allows configuring etherpad plugin" do
    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    expect(settings).to be_nil

    get "/plugins/etherpad"

    multiple_accounts_select
    f("#plugin_setting_disabled").click
    wait_for_ajaximations
    f("#settings_domain").send_keys("asdf")
    submit_form("#new_plugin_setting")

    assert_flash_error_message "There was an error"

    f("#settings_name").send_keys("asdf")
    submit_form("#new_plugin_setting")
    wait_for_ajax_requests

    assert_flash_notice_message "successfully updated"

    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    expect(settings).not_to be_nil
    expect(settings[:domain]).to eq "asdf"
    expect(settings[:name]).to eq "asdf"
  end

  def multiple_accounts_select
    unless f("#plugin_setting_disabled").displayed?
      f("#accounts_select option:nth-child(2)").click
      expect(f("#plugin_setting_disabled")).to be_displayed
    end
    unless f(".save_button").enabled?
      f(".copy_settings_button").click
    end
  end
end
