#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../common'
require_relative './new_user_search_page'
require_relative './new_user_edit_modal_page.rb'
require_relative './masquerade_page.rb'
require_relative '../conversations/conversations_new_message_modal_page.rb'

describe "new account user search" do
  include_context "in-process server selenium tests"

  before :once do
    @account = Account.default
    account_admin_user(:account => @account, :active_all => true)
  end

  before do
    user_session(@user)
  end

  def get_rows
    ff('[data-automation="users list"] tr')
  end

  def wait_for_loading_to_disappear
    expect(f('[data-automation="users list"]')).not_to contain_css('tr:nth-child(2)')
  end

  it "should be able to toggle between 'People' and 'Courses' tabs" do
    user_with_pseudonym(:account => @account, :name => "Test User")
    course_factory(:account => @account, :course_name => "Test Course")

    get "/accounts/#{@account.id}"
    2.times do
      expect(f("#breadcrumbs")).not_to include_text("People")
      expect(f("#breadcrumbs")).to include_text("Courses")
      expect(f('[data-automation="courses list"]')).to include_text("Test Course")

      f('#section-tabs .users').click
      expect(driver.current_url).to include("/accounts/#{@account.id}/users")
      expect(f("#breadcrumbs")).to include_text("People")
      expect(f("#breadcrumbs")).not_to include_text("Courses")
      expect(f('[data-automation="users list"]')).to include_text("Test User")

      f('#section-tabs .courses').click
    end
  end

  it "should not show the people tab without permission" do
    @account.role_overrides.create! :role => admin_role, :permission => 'read_roster', :enabled => false

    get "/accounts/#{@account.id}"

    expect(f("#left-side #section-tabs")).not_to include_text("People")
  end

  it "should show the create users button user has permission on the root_account" do
    sub_account = Account.create!(name: "sub", parent_account: @account)
    get "/accounts/#{sub_account.id}/users"

    expect(f("#content")).to contain_jqcss('button:has([name="IconPlus"]):contains("People")')
  end

  it "should be able to create users" do
    get "/accounts/#{@account.id}/users"

    fj('button:has([name="IconPlus"]):contains("People")').click
    modal = f('[aria-label="Add a New User"]')
    expect(modal).to be_displayed

    name = 'Test User'
    set_value(fj('label:contains("Full Name") input', modal), name)
    expect(fj('label:contains("Sortable Name") input', modal).attribute('value')).to eq "User, Test"

    email = 'someemail@example.com'
    set_value(fj('label:contains("Email") input', modal), email)

    f('button[type="submit"]', modal).click
    wait_for_ajaximations

    new_pseudonym = Pseudonym.where(:unique_id => email).first
    expect(new_pseudonym.user.name).to eq name

    # should refresh the users list
    expect(f('[data-automation="users list"]')).to include_text(name)
    expect(get_rows.count).to eq 2 # the first user is the admin
    new_row = get_rows.detect{|r| r.text.include?(name)}
    expect(new_row).to include_text(email)

    # should clear out the inputs
    fj('button:has([name="IconPlus"]):contains("People")').click
    expect(fj('[aria-label="Add a New User"] label:contains("Full Name") input').attribute('value')).to eq('')
  end

  it "should be able to create users with confirmation disabled", priority: "1", test_id: 3399311 do
    name = 'Confirmation Disabled'
    get "/accounts/#{@account.id}/users"

    fj('button:has([name="IconPlus"]):contains("People")').click
    modal = f('[aria-label="Add a New User"]')

    set_value(fj('label:contains("Full Name") input', modal), name)

    email = 'someemail@example.com'
    set_value(fj('label:contains("Email") input', modal), email)

    fj('label:contains("Email the user about this account creation")', modal).click

    f('button[type="submit"]', modal).click
    wait_for_ajaximations

    new_pseudonym = Pseudonym.where(:unique_id => email).first
    expect(new_pseudonym.user.name).to eq name
  end

  it "should paginate" do
    ('A'..'Z').each do |letter|
      user_with_pseudonym(:account => @account, :name => "Test User #{letter}")
    end

    get "/accounts/#{@account.id}/users"

    expect(get_rows.count).to eq 15
    expect(get_rows.first).to include_text("Test User A")
    expect(f("[data-automation='users list']")).to_not include_text("Test User O")
    expect(f("#content")).not_to contain_css('button[title="Previous Page"]')

    fj('nav button:contains("2")').click
    wait_for_ajaximations

    expect(get_rows.count).to eq 12
    expect(get_rows.first).to include_text("Test User O")
    expect(get_rows.last).to include_text("Test User Z")
    expect(f("[data-automation='users list']")).not_to include_text("Test User A")
  end

  # This describe block will be removed once all tests are converted
  describe 'Page Object Converted Tests Root Account' do
    include NewUserSearchPage
    include NewUserEditModalPage
    include MasqueradePage
    include ConversationsNewMessageModalPage

    before do
      @user.update_attribute(:name, "Test User")
      visit(@account)
    end

    it "should bring up user page when clicking name", priority: "1", test_id: 3399648 do
      click_user_link(@user.name)
      expect(f("#content h2")).to include_text @user.name
    end

    it "should open the edit user modal when clicking the edit user icon" do
      click_edit_button(@user.name)
      expect(full_name_input.attribute('value')).to eq(@user.name)
    end

    it "should open the act as page when clicking the masquerade button", priority: "1", test_id: 3453424 do
      click_masquerade_button(@user.name)
      expect(act_as_label).to include_text @user.name
    end

    it "should open the conversation page when clicking the send message button", priority: "1", test_id: 3453435 do
      click_message_button(@user.name)
      expect(message_recipient_input).to include_text @user.name
    end

    it "should search but not find bogus user", priority: "1", test_id: 3399649 do
      enter_search('jtsdumbthing')
      expect(results_alert).to include_text('No users found')
      expect(results_body).not_to contain_css(results_row)
    end

    it "should link to the user group page" do
      click_people_more_options
      click_view_user_groups_option
      expect(driver.current_url).to include("/accounts/#{@account.id}/groups")
    end

    it "should link to the user avatar page" do
      click_people_more_options
      click_manage_profile_pictures_option
      expect(driver.current_url).to include("/accounts/#{@account.id}/avatars")
    end

    it "should search by name" do
      user_with_pseudonym(:account => @account, :name => "diffrient user")
      enter_search("Test")
      wait_for_loading_to_disappear
      expect(results_rows.count).to eq 1
      expect(results_rows.first).to include_text("Test")
    end
  end

  describe 'Page Object Converted Tests Sub Account' do
    include NewUserSearchPage
    include NewUserEditModalPage
    include MasqueradePage
    include ConversationsNewMessageModalPage

    before do
      @user.update_attribute(:name, "Test User")
      @sub_account = Account.create!(name: "sub", parent_account: @account)
      visit_subaccount(@sub_account)
    end

    it "should not show the create users button for non-root accounts" do
      account_admin_user(account: @sub_account, active_all: true)
      expect(results_body).not_to contain_jqcss(add_user_button_jqcss)
    end
  end
end
