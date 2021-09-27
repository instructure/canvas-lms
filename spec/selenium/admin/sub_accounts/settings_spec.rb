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

require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/settings_specs')

describe "sub account basic settings" do
  let(:account) { Account.create(name: 'sub account from default account', parent_account: Account.default) }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:admin_tab_url) { "/accounts/#{account.id}/settings#tab-users" }
  include_examples "settings basic tests", :sub_account

  it "should disable inherited settings if locked by a parent account", priority: "1", test_id: 250007 do
    parent = Account.default
    parent.settings[:restrict_student_future_view] = {locked: true, value: true}
    parent.save!

    get account_settings_url

    expect(f('#account_settings_restrict_student_past_view_value')).not_to be_disabled
    expect(f('#account_settings_restrict_student_past_view_locked')).not_to be_nil

    expect(f('#account_settings_restrict_student_future_view_value')).to be_disabled
    expect(f("#account_settings")).not_to contain_css('#account_settings_restrict_student_future_view_locked') # don't even show the locked checkbox

    expect(is_checked('#account_settings_restrict_student_future_view_value')).to be_truthy
  end
end
