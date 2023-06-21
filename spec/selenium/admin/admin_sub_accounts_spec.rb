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

  def click_account_action_link(account_id, action_link_css)
    f("#account_#{account_id} #{action_link_css}").click
  end

  def create_sub_account_and_go
    sub_account = create_sub_account
    get "/accounts/#{default_account_id}/sub_accounts"
    sub_account
  end

  def edit_account_info(input_css, text_to_input)
    new_account_input = f(input_css)
    new_account_input.send_keys(text_to_input)
    new_account_input.send_keys(:return)
    wait_for_ajaximations
  end

  before do
    course_with_admin_logged_in
  end

  it "creates a new sub account" do
    get "/accounts/#{default_account_id}/sub_accounts"
    new_account_name = "new sub account"
    click_account_action_link(default_account_id, ".add_sub_account_link")
    edit_account_info("#new_account #account_name", new_account_name)
    sub_accounts = ff(".sub_accounts .sub_account")
    check_element_has_focus f(".account > .header .name", sub_accounts[0])
    expect(sub_accounts.count).to eq 1
    expect(sub_accounts[0]).to include_text(new_account_name)
    expect(Account.last.name).to eq new_account_name
  end

  it "deletes a sub account" do
    sub_account = create_sub_account_and_go
    expect do
      click_account_action_link(sub_account.id, ".delete_account_link")
      driver.switch_to.alert.accept
      wait_for_ajaximations
    end.to change(Account.default.sub_accounts, :count).by(-1)
    check_element_has_focus f("#account_#{Account.default.id} > .header .name")
    expect(f(".sub_accounts")).not_to contain_css(".sub_account")
  end

  it "edits a sub account" do
    edit_name = "edited sub account"
    sub_account = create_sub_account_and_go
    click_account_action_link(sub_account.id, ".edit_account_link")
    edit_account_info("#account_#{sub_account.id} #account_name", edit_name)
    check_element_has_focus f("#account_#{sub_account.id} > .header .name")
    expect(f("#account_#{sub_account.id}")).to include_text(edit_name)
    expect(Account.where(id: sub_account).first.name).to eq edit_name
  end

  it "validates sub account count on main account" do
    get "/accounts/#{default_account_id}/sub_accounts"
    expect(f(".sub_accounts_count")).not_to be_displayed
    create_sub_account
    refresh_page # to make new sub account show up
    expect(f(".sub_accounts_count").text).to eq "1 Sub-Account"
  end

  it "is able to nest sub accounts" do
    expected_second_sub_account_name = "second sub account 0"
    first_sub = create_sub_account
    second_sub = create_sub_account("second sub account", 1, first_sub)
    sub_accounts = [first_sub, second_sub]
    Account.default.sub_accounts.each_with_index { |account, i| expect(account.name).to eq sub_accounts[i].name }
    get "/accounts/#{default_account_id}/sub_accounts"
    expect(first_sub.sub_accounts.first.name).to eq expected_second_sub_account_name
    first_sub_account = f("#account_#{first_sub.id}")
    expect(first_sub_account.find_element(:css, ".sub_accounts_count").text).to eq "1 Sub-Account"
    expect(first_sub_account.find_element(:css, ".sub_account")).to include_text(second_sub.name)
  end

  it "hides sub accounts and re-expand them" do
    def check_sub_accounts(displayed = true)
      sub_accounts = ff(".sub_accounts .sub_account")
      displayed ? sub_accounts.each { |account| expect(account).to be_displayed } : sub_accounts.each { |account| expect(account).not_to be_displayed }
    end

    create_sub_account("sub account", 5)
    get "/accounts/#{default_account_id}/sub_accounts"
    check_sub_accounts
    click_account_action_link(default_account_id, ".collapse_sub_accounts_link")
    wait_for_ajaximations
    check_element_has_focus f("#account_#{default_account_id} > .header .expand_sub_accounts_link")
    check_sub_accounts(false)
    click_account_action_link(default_account_id, ".expand_sub_accounts_link")
    wait_for_ajaximations
    check_element_has_focus f("#account_#{default_account_id} > .header .collapse_sub_accounts_link")
    check_sub_accounts
  end

  it "validates course count for a sub account" do
    def validate_course_count(account_id, count_text)
      expect(f("#account_#{account_id} .courses_count").text).to eq count_text
    end

    added_courses_count = 3
    get "/accounts/#{default_account_id}/sub_accounts"

    validate_course_count(default_account_id, "1 Course") # make sure default account was setup correctly
    sub_account = create_sub_account("add courses to me")
    added_courses_count.times { Course.create!(account: sub_account) }
    refresh_page # to make new account with courses show up
    validate_course_count(sub_account.id, "3 Courses")
  end

  it "validates that you can't delete a sub account with courses in it" do
    get "/accounts/#{default_account_id}/sub_accounts"
    click_account_action_link(default_account_id, ".cant_delete_account_link")
    expect(driver.switch_to.alert.text).to eq "You can't delete a sub-account that has courses in it"
    driver.switch_to.alert.accept
    expect(Account.default.workflow_state).to eq "active"
  end
end
