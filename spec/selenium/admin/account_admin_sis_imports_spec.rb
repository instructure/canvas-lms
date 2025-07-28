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

  it "creates SisBatch with no options" do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    f("input[type=file]").send_keys Rails.root.join("spec/fixtures/sis/utf8.csv")
    f("button[type='submit']").click
    expect(f(".progress_bar_holder .progress_message")).to be_displayed
    expect(SisBatch.last.batch_mode).to be_nil
    expect(SisBatch.last.options).to eq({ skip_deletes: false, update_sis_id_if_login_claimed: false })
  end

  it "creates SisBatch with options" do
    account_with_admin_logged_in
    @account.update_attribute(:allow_sis_import, true)
    get "/accounts/#{@account.id}/sis_import"
    f("label[for='override_sis_stickiness']").click
    f("label[for='add_sis_stickiness']").click
    f("label[for='batch_mode']").click
    f("input[type=file]").send_keys Rails.root.join("spec/fixtures/sis/utf8.csv")
    f("button[type='submit']").click
    f("#confirmation_modal_confirm").click
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
