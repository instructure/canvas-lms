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

require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "new account user search" do
  include_context "in-process server selenium tests"

  before :once do
    @account = Account.default
    @account.enable_feature!(:course_user_search)
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

  it "should not show the create users button for non-root acocunts" do
    sub_account = Account.create!(name: "sub", parent_account: @account)
    account_admin_user(account: sub_account, active_all: true)
    user_session(@user)

    get "/accounts/#{sub_account.id}/users"

    expect(f("#content")).not_to contain_jqcss('button:has([name="IconPlusLine"]):contains("People")')
  end

  it "should show the create users button user has permission on the root_account" do
    sub_account = Account.create!(name: "sub", parent_account: @account)
    get "/accounts/#{sub_account.id}/users"

    expect(f("#content")).to contain_jqcss('button:has([name="IconPlusLine"]):contains("People")')
  end

  it "should be able to create users" do
    get "/accounts/#{@account.id}/users"

    fj('button:has([name="IconPlusLine"]):contains("People")').click
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
    fj('button:has([name="IconPlusLine"]):contains("People")').click
    expect(fj('[aria-label="Add a New User"] label:contains("Full Name") input').attribute('value')).to eq('')
  end

  it "should be able to create users with confirmation disabled", priority: "1", test_id: 3399311 do
    name = 'Confirmation Disabled'
    get "/accounts/#{@account.id}/users"

    fj('button:has([name="IconPlusLine"]):contains("People")').click
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

  it "should bring up user page when clicking name", priority: "1", test_id: 3399648 do
    page_user = user_with_pseudonym(:account => @account, :name => "User Page")
    get "/accounts/#{@account.id}/users"

    fj("[data-automation='users list'] tr a:contains('#{page_user.name}')").click

    wait_for_ajax_requests
    expect(f("#content h2")).to include_text page_user.name
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

    f('button[title="Next Page"]').click
    wait_for_ajaximations

    expect(get_rows.count).to eq 12
    expect(get_rows.first).to include_text("Test User O")
    expect(get_rows.last).to include_text("Test User Z")
    expect(f("[data-automation='users list']")).not_to include_text("Test User A")
    expect(f("#content")).to contain_css('button[title="Previous Page"]')
    expect(f("#content")).not_to contain_css('button[title="Next Page"]')
  end

  it "should search by name" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}/users"

    f('input[placeholder="Search people..."]').send_keys('search')
    wait_for_loading_to_disappear

    rows = get_rows
    expect(rows.count).to eq 1
    expect(rows.first).to include_text(match_user.name)
  end

  it "should search but not find bogus user", priority: "1", test_id: 3399649 do
    bogus = 'jtsdumbthing'
    get "/accounts/#{@account.id}/users"

    f('input[placeholder="Search people..."]').send_keys(bogus)

    expect(f('#content .alert')).to include_text('No users found')
    expect(f('#content')).not_to contain_css('[data-automation="users list"] tr')
  end

  it "should link to the user avatar page" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}/users"

    fj('button:contains("More People Options")').click
    fj('[role="menuitem"]:contains("Manage profile pictures")').click

    expect(driver.current_url).to include("/accounts/#{@account.id}/avatars")
  end

  it "should link to the user group page" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}/users"

    fj('button:contains("More People Options")').click
    fj('[role="menuitem"]:contains("View user groups")').click

    expect(driver.current_url).to include("/accounts/#{@account.id}/groups")
  end

  it "should open the act as page when clicking the masquerade button", priority: "1", test_id: 3453424 do
    mask_user = user_with_pseudonym(:account => @account, :name => "Mask User", :active_user => true)

    get "/accounts/#{@account.id}/users"

    fj("[data-automation='users list'] tr:contains('#{mask_user.name}') [role=button]:has([name='IconMasqueradeLine'])")
      .click
    expect(f('.ActAs__text')).to include_text mask_user.name
  end

  it "should open the conversation page when clicking the send message button", priority: "1", test_id: 3453435 do
    conv_user = user_with_pseudonym(:account => @account, :name => "Conversation User")

    get "/accounts/#{@account.id}/users"

    fj("[data-automation='users list'] tr:contains('#{conv_user.name}') [role=button]:has([name='IconMessageLine'])")
      .click
    expect(f('.message-header-input .ac-token')).to include_text conv_user.name
  end

  it "should open the edit user modal when clicking the edit user button", priority: "1", test_id: 3453436 do
    edit_user = user_with_pseudonym(:account => @account, :name => "Edit User")

    get "/accounts/#{@account.id}/users"

    fj("[data-automation='users list'] tr:contains('#{edit_user.name}') [role=button]:has([name='IconEditLine'])").click

    expect(fj('label:contains("Full Name") input').attribute('value')).to eq("Edit User")
  end

end
