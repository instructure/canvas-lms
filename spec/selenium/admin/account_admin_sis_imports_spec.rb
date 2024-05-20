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

describe "sis imports ui" do
  include_context "in-process server selenium tests"

  def account_with_admin_logged_in
    @account = Account.default
    account_admin_user
    user_session(@admin)
  end

  it "properly shows sis stickiness options" do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    expect(f("#add_sis_stickiness")).not_to be_displayed
    expect(f("#clear_sis_stickiness")).not_to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(f("#add_sis_stickiness")).to be_enabled
    expect(f("#clear_sis_stickiness")).to be_enabled
    expect(f("#override_sis_stickiness")).to be_enabled
    expect(is_checked("#add_sis_stickiness")).to be_falsey
    expect(is_checked("#clear_sis_stickiness")).to be_falsey
    # #override_sis_stickiness is an <input> element, so .prop('checked') is appropriate
    expect(driver.execute_script("return $('#override_sis_stickiness').prop('checked')")).to be false
    expect(is_checked("#override_sis_stickiness")).to be_falsey
    f("#override_sis_stickiness").click
    expect(f("#add_sis_stickiness")).to be_displayed
    expect(f("#clear_sis_stickiness")).to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(f("#add_sis_stickiness")).to be_enabled
    expect(f("#clear_sis_stickiness")).to be_enabled
    expect(f("#override_sis_stickiness")).to be_enabled
    expect(is_checked("#add_sis_stickiness")).to be_falsey
    expect(is_checked("#clear_sis_stickiness")).to be_falsey
    expect(is_checked("#override_sis_stickiness")).to be_truthy
    f("#override_sis_stickiness").click

    expect(f("#add_sis_stickiness")).not_to be_displayed
    expect(f("#clear_sis_stickiness")).not_to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(f("#add_sis_stickiness")).to be_enabled
    expect(f("#clear_sis_stickiness")).to be_enabled
    expect(f("#override_sis_stickiness")).to be_enabled
    expect(is_checked("#add_sis_stickiness")).to be_falsey
    expect(is_checked("#clear_sis_stickiness")).to be_falsey
    expect(is_checked("#override_sis_stickiness")).to be_falsey
    f("#override_sis_stickiness").click
    f("#add_sis_stickiness").click

    expect(f("#add_sis_stickiness")).to be_displayed
    expect(f("#clear_sis_stickiness")).to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(f("#add_sis_stickiness")).to be_enabled
    expect(f("#clear_sis_stickiness")).not_to be_enabled
    expect(f("#override_sis_stickiness")).to be_enabled
    expect(is_checked("#add_sis_stickiness")).to be_truthy
    expect(is_checked("#clear_sis_stickiness")).to be_falsey
    expect(is_checked("#override_sis_stickiness")).to be_truthy
    f("#add_sis_stickiness").click

    expect(f("#add_sis_stickiness")).to be_displayed
    expect(f("#clear_sis_stickiness")).to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(f("#add_sis_stickiness")).to be_enabled
    expect(f("#clear_sis_stickiness")).to be_enabled
    expect(f("#override_sis_stickiness")).to be_enabled
    expect(is_checked("#add_sis_stickiness")).to be_falsey
    expect(is_checked("#clear_sis_stickiness")).to be_falsey
    expect(is_checked("#override_sis_stickiness")).to be_truthy
    f("#clear_sis_stickiness").click

    expect(f("#add_sis_stickiness")).to be_displayed
    expect(f("#clear_sis_stickiness")).to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(f("#add_sis_stickiness")).not_to be_enabled
    expect(f("#clear_sis_stickiness")).to be_enabled
    expect(f("#override_sis_stickiness")).to be_enabled

    expect(is_checked("#add_sis_stickiness")).to be_falsey
    expect(is_checked("#clear_sis_stickiness")).to be_truthy
    expect(is_checked("#override_sis_stickiness")).to be_truthy
    f("#clear_sis_stickiness").click

    expect(f("#add_sis_stickiness")).to be_displayed
    expect(f("#clear_sis_stickiness")).to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(f("#add_sis_stickiness")).to be_enabled
    expect(f("#clear_sis_stickiness")).to be_enabled
    expect(f("#override_sis_stickiness")).to be_enabled

    expect(is_checked("#add_sis_stickiness")).to be_falsey
    expect(is_checked("#clear_sis_stickiness")).to be_falsey
    expect(is_checked("#override_sis_stickiness")).to be_truthy
    f("#clear_sis_stickiness").click
    f("#override_sis_stickiness").click

    expect(f("#add_sis_stickiness")).not_to be_displayed
    expect(f("#clear_sis_stickiness")).not_to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(is_checked("#override_sis_stickiness")).to be_falsey
    f("#override_sis_stickiness").click
    f("#clear_sis_stickiness").click
    f("#add_sis_stickiness").click
    f("#override_sis_stickiness").click

    expect(f("#add_sis_stickiness")).not_to be_displayed
    expect(f("#clear_sis_stickiness")).not_to be_displayed
    expect(f("#override_sis_stickiness")).to be_displayed
    expect(is_checked("#override_sis_stickiness")).to be_falsey
  end

  it "passes options along to the batch" do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    f("#override_sis_stickiness").click
    f("#add_sis_stickiness").click
    f("#batch_mode").click
    f("input[type=file]").send_keys Rails.root.join("spec/fixtures/sis/utf8.csv")
    submit_form("#sis_importer")
    expect(f(".progress_bar_holder .progress_message")).to be_displayed
    expect(SisBatch.last.batch_mode).to be true
    expect(SisBatch.last.options).to eq({
                                          skip_deletes: false,
                                          override_sis_stickiness: true,
                                          add_sis_stickiness: true,
                                          update_sis_id_if_login_claimed: false
                                        })
  end
end
