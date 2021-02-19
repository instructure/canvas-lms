# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/settings_specs')

describe "root account basic settings" do
  let(:account) { Account.default }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }
  include_examples "settings basic tests", :root_account

  before(:each) do
    Account.default.enable_feature!(:rce_enhancements)
    stub_rcs_config
  end

  it "should change the default user quota", priority: "1", test_id: 250002 do
    course_with_admin_logged_in
    group_model(context: @course)
    get account_settings_url

    f('#tab-quotas-link').click

    # update the quotas
    user_quota = account.default_user_storage_quota_mb
    user_quota_input = f('[name="default_user_storage_quota_mb"]')
    expect(user_quota_input).to have_value(user_quota.to_s)

    user_quota += 15
    replace_content(user_quota_input, user_quota.to_s)

    submit_form('#default-quotas')
    wait_for_ajax_requests

    # ensure the account was updated properly
    account.reload
    expect(account.default_user_storage_quota).to eq user_quota * 1048576

    # ensure the new value is reflected after a refresh
    get account_settings_url
    expect(fj('[name="default_user_storage_quota_mb"]')).to have_value(user_quota.to_s) # fj to avoid selenium caching
  end

  it "should be able to remove account quiz ip filters" do
    account.ip_filters = {"name" => "192.168.217.1/24"}
    account.save!

    course_with_admin_logged_in
    get account_settings_url

    expect_new_page_load { submit_form("#account_settings") }

    account.reload
    expect(account.settings[:ip_filters]).to be_present # should not have cleared them if we didn't do anything

    filter = ff('.ip_filter').detect{|fil| fil.displayed?}
    filter.find_element(:css, '.delete_filter_link').click

    expect_new_page_load { submit_form("#account_settings") }

    account.reload
    expect(account.settings[:ip_filters]).to be_blank
  end
end
