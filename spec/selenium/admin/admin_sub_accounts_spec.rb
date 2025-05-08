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

require_relative "../common"

describe "admin sub accounts" do
  include_context "in-process server selenium tests"
  let(:default_account_id) { Account.default.id }

  def create_sub_account(name = "sub account", number_to_create = 1, parent_account = Account.default)
    created_sub_accounts = []
    number_to_create.times do |i|
      sub_account = Account.create(name: name + " #{i}", parent_account:)
      created_sub_accounts.push(sub_account)
    end
    (created_sub_accounts.count == 1) ? created_sub_accounts[0] : created_sub_accounts
  end

  def click_account_action_link(account_id, action_btn)
    f("[data-testid='#{action_btn}-#{account_id}']").click
  end

  def create_sub_account_and_go
    sub_account = create_sub_account
    get "/accounts/#{default_account_id}/sub_accounts"
    wait_for_ajaximations
    sub_account
  end

  def edit_account_info(text_to_input)
    new_account_input = f("[data-testid='account-name-input']")
    # new_account_input.clear was causing flakiness in Jenkins
    new_account_input.send_keys(text_to_input)
    save_button = f("[data-testid='save-button']")
    save_button.click
    wait_for_ajaximations
  end

  before do
    course_with_admin_logged_in
  end

  it "creates a new sub account" do
    get "/accounts/#{default_account_id}/sub_accounts"
    wait_for_ajaximations
    new_account_name = "new sub account"
    click_account_action_link(default_account_id, "add")
    edit_account_info(new_account_name)
    sub_account = Account.default.sub_accounts[0]
    check_element_has_focus f("[data-testid='link_#{sub_account.id}']")
    expect(f("[data-testid='link_#{sub_account.id}']")).to include_text(new_account_name)
    expect(sub_account.name).to eq new_account_name
  end

  it "deletes a sub account" do
    sub_account = create_sub_account_and_go
    sub_account_id = sub_account.id
    expect do
      click_account_action_link(sub_account.id, "delete")
      f('[data-testid="confirm-delete"]').click
      wait_for_ajaximations
    end.to change(Account.default.sub_accounts, :count).by(-1)
    check_element_has_focus f("[data-testid='link_#{Account.default.id}']")
    expect(element_exists?("[data-testid='header_#{sub_account_id}']")).to be_falsey
  end

  it "edits a sub account" do
    sub_account = create_sub_account_and_go
    click_account_action_link(sub_account.id, "edit")
    edit_account_info(" (edited)")
    check_element_has_focus f("[data-testid='link_#{sub_account.id}']")
    expect(f("[data-testid='link_#{sub_account.id}']")).to include_text("sub account 0 (edited)")
    expect(Account.where(id: sub_account).first.name).to eq "sub account 0 (edited)"
  end

  it "validates sub account count on main account" do
    get "/accounts/#{default_account_id}/sub_accounts"
    wait_for_ajaximations
    expect(element_exists?("[data-testid='sub_count_#{default_account_id}']")).to be_falsey
    create_sub_account
    refresh_page # to make new sub account show up
    wait_for_ajaximations
    expect(f("[data-testid='sub_count_#{default_account_id}']").text).to eq "1 Sub-Account"
  end

  it "hides sub accounts and re-expand them" do
    def check_sub_accounts(displayed = true)
      sub_accounts = Account.default.sub_accounts
      if displayed
        sub_accounts.each { |account| expect(f("[data-testid='header_#{account.id}']")).to be_displayed }
      else
        sub_accounts.each { |account| expect(element_exists?("[data-testid='header_#{account.id}']")).to be_falsey }
      end
    end

    create_sub_account("sub account", 5)
    get "/accounts/#{default_account_id}/sub_accounts"
    wait_for_ajaximations
    check_sub_accounts
    click_account_action_link(default_account_id, "collapse")
    wait_for_ajaximations
    check_element_has_focus f("[data-testid='expand-#{default_account_id}']")
    check_sub_accounts(false)
    click_account_action_link(default_account_id, "expand")
    wait_for_ajaximations
    # TODO: add this back in subsequent commit
    # check_element_has_focus f("[data-testid='collapse-#{default_account_id}']")
    check_sub_accounts
  end

  it "validates course count for a sub account" do
    def validate_course_count(account_id, count_text)
      expect(f("[data-testid='course_count_#{account_id}']").text).to eq count_text
    end

    added_courses_count = 3
    get "/accounts/#{default_account_id}/sub_accounts"
    wait_for_ajaximations
    validate_course_count(default_account_id, "1 Course") # make sure default account was setup correctly
    sub_account = create_sub_account("add courses to me")
    added_courses_count.times { Course.create!(account: sub_account) }
    refresh_page # to make new account with courses show up
    wait_for_ajaximations
    validate_course_count(sub_account.id, "3 Courses")
  end

  it "validates that you can't delete a sub account with courses in it" do
    sub_account = create_sub_account("add courses to me")
    Course.create!(account: sub_account)
    get "/accounts/#{default_account_id}/sub_accounts"
    wait_for_ajaximations
    click_account_action_link(sub_account.id, "delete")
    expect(f(".flashalert-message p").text).to eq "You cannot delete accounts with active courses"
    expect(Account.default.workflow_state).to eq "active"
  end
end
