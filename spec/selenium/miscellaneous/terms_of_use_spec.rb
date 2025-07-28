# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

def login
  get "/login"
  expect_new_page_load { fill_in_login_form("nobody@example.com", "asdfasdf") }
end
describe "terms of use test" do
  include_context "in-process server selenium tests"

  before do
    user_with_pseudonym(active_user: true)
  end

  it "does not require a user to accept the terms if they haven't changed", priority: "1" do
    login
    expect(f("#content")).not_to contain_css(".reaccept_terms")
  end

  it "does not require a user to accept the terms if already logged in when they change", priority: "2" do
    create_session(@pseudonym)
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    get "/"
    expect(f("#content")).not_to contain_css(".reaccept_terms")
  end

  context "editing terms_of_use" do
    before :once do
      account_admin_user(account: Account.site_admin)
      @account = Account.default
    end

    before do
      user_session(@admin)
    end

    it "is able to update custom terms" do
      get "/accounts/#{@account.id}/settings"
      expect(f("#account_settings")).to be_present
      click_option("#account_terms_of_service_terms_type", "custom", :value)
      rce_container = f("#custom_tos_rce_container")
      expect(rce_container).to be_displayed
      wait_for_tiny(f("#custom_tos_rce_container textarea"))
      type_in_tiny("textarea", "stuff")
      submit_form("#account_settings")

      expect_new_page_load do
        submit_form("#account_settings")
      end

      @account.reload
      expect(@account.terms_of_service.terms_of_service_content.content).to include("stuff")
    end

    it "populates the custom terms in the text area" do
      @account.update_terms_of_service({ terms_type: "custom", content: "other stuff" }, @admin)

      get "/accounts/#{@account.id}/settings"

      wait_for_tiny(f("#custom_tos_rce_container textarea"))
      expect_new_page_load { submit_form("#account_settings") }
      expect(@account.reload.terms_of_service.terms_of_service_content.content).to include("other stuff") # should be unchanged
    end
  end

  it "requires a user to accept the terms if they have changed", priority: "1" do
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    login
    form = f(".reaccept_terms")
    expect(form).to be_present
    expect_new_page_load do
      f('[name="user[terms_of_use]"]').click
      submit_form form
    end
    expect(f("#content")).not_to contain_css(".reaccept_terms")
  end

  it "requires users to check the box" do
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!

    login

    form = f(".reaccept_terms")
    expect(form).to be_present
    submit_form form
    wait_for_ajaximations

    expect(ff(".error_box").any?(&:displayed?)).to be_truthy
    expect(account.require_acceptance_of_terms?(@user.reload)).to be_truthy

    expect_new_page_load do
      f('[name="user[terms_of_use]"]').click
      submit_form form
    end
    expect(account.require_acceptance_of_terms?(@user.reload)).to be_falsey
  end

  it "prevents them from using canvas if the terms have changed", priority: "1" do
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    login
    # try to view a different page
    get "/profile/settings"
    expect(f(".reaccept_terms")).to be_present
  end
end

describe "terms of use SOC2 compliance test" do
  include_context "in-process server selenium tests"

  it "prevents a user from accessing canvas if they are newly registered/imported after the SOC2 start date and have not yet accepted the terms" do
    # Create a user after SOC2 implemented
    after_soc2_start_date = Setting.get("SOC2_start_date", Time.new(2015, 5, 16, 0, 0, 0).utc).to_time + 10.days

    Timecop.freeze(after_soc2_start_date) do
      user_with_pseudonym
      @user.register!
    end

    login

    # terms page should be displayed
    expect(f(".reaccept_terms")).to be_present

    # try to view a different page, terms page should remain
    get "/profile/settings"
    form = f(".reaccept_terms")
    expect(form).to be_present

    # accept the terms
    expect_new_page_load do
      f('[name="user[terms_of_use]"]').click
      submit_form form
    end

    expect(f("#content")).not_to contain_css(".reaccept_terms")
  end

  it "grandfathers in previously registered users without prompting them to reaccept the terms", priority: "1" do
    # Create a user before SOC2 implemented
    before_soc2_start_date = Setting.get("SOC2_start_date", Time.new(2015, 5, 16, 0, 0, 0).utc).to_time - 10.days

    Timecop.freeze(before_soc2_start_date) do
      user_with_pseudonym
      @user.register!
    end

    login

    # terms page shouldn't be visible
    expect(f("#content")).not_to contain_css(".reaccept_terms")

    # view a different page, verify terms page isn't displayed
    get "/profile/settings"
    expect(f("#content")).not_to contain_css(".reaccept_terms")
  end
end
