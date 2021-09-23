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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "default plugins" do
  include_context "in-process server selenium tests"

  before(:each) do
    user_logged_in
    Account.site_admin.account_users.create!(user: @user)
  end

  it "should allow configuring twitter plugin" do
    settings = Canvas::Plugin.find(:twitter).try(:settings)
    expect(settings).to be_nil

    allow(Twitter::Connection).to receive(:config_check).and_return("Bad check")
    get "/plugins/twitter"

    multiple_accounts_select
    f("#plugin_setting_disabled").click
    wait_for_ajaximations
    f("#settings_consumer_key").send_keys("asdf")
    f("#settings_consumer_secret").send_keys("asdf")
    submit_form('#new_plugin_setting')

    assert_flash_error_message "There was an error"

    f("#settings_consumer_secret").send_keys("asdf")
    allow(Twitter::Connection).to receive(:config_check).and_return(nil)

    submit_form('#new_plugin_setting')
    wait_for_ajax_requests

    assert_flash_notice_message "successfully updated"

    settings = Canvas::Plugin.find(:twitter).try(:settings)
    expect(settings).not_to be_nil
    expect(settings[:consumer_key]).to eq 'asdf'
    expect(settings[:consumer_secret_dec]).to eq 'asdf'
  end

  it "should allow configuring etherpad plugin" do
    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    expect(settings).to be_nil

    get "/plugins/etherpad"

    multiple_accounts_select
    f("#plugin_setting_disabled").click
    wait_for_ajaximations
    f("#settings_domain").send_keys("asdf")
    submit_form('#new_plugin_setting')

    assert_flash_error_message "There was an error"

    f("#settings_name").send_keys("asdf")
    submit_form('#new_plugin_setting')
    wait_for_ajax_requests

    assert_flash_notice_message "successfully updated"

    settings = Canvas::Plugin.find(:etherpad).try(:settings)
    expect(settings).not_to be_nil
    expect(settings[:domain]).to eq 'asdf'
    expect(settings[:name]).to eq 'asdf'
  end

  it "should allow configuring linked in plugin" do
    settings = Canvas::Plugin.find(:linked_in).try(:settings)
    expect(settings).to be_nil

    allow(LinkedIn::Connection).to receive(:config_check).and_return("Bad check")
    get "/plugins/linked_in"

    multiple_accounts_select
    f("#plugin_setting_disabled").click
    wait_for_ajaximations
    f("#settings_client_id").send_keys("asdf")
    f("#settings_client_secret").send_keys("asdf")
    submit_form('#new_plugin_setting')

    assert_flash_error_message "There was an error"

    f("#settings_client_secret").send_keys("asdf")
    allow(LinkedIn::Connection).to receive(:config_check).and_return(nil)
    submit_form('#new_plugin_setting')
    wait_for_ajax_requests

    assert_flash_notice_message "successfully updated"

    settings = Canvas::Plugin.find(:linked_in).try(:settings)
    expect(settings).not_to be_nil
    expect(settings[:client_id]).to eq 'asdf'
    expect(settings[:client_secret_dec]).to eq 'asdf'
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

