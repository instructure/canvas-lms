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
    account_model
    @account.enable_feature!(:course_user_search)
    account_admin_user(:account => @account, :active_all => true)
  end

  before do
    user_session(@user)
  end

  def get_rows
    ff('.users-list div[role=row]')
  end

  it "should be able to toggle between 'People' and 'Courses' tabs" do
    user_with_pseudonym(:account => @account, :name => "Test User")
    course_factory(:account => @account, :course_name => "Test Course")

    get "/accounts/#{@account.id}"
    2.times do
      expect(f("#breadcrumbs")).not_to include_text("People")
      expect(f("#breadcrumbs")).to include_text("Courses")
      expect(f('.courses-list')).to include_text("Test Course")

      f('#section-tabs .users').click
      expect(driver.current_url).to include("/accounts/#{@account.id}/users")
      expect(f("#breadcrumbs")).to include_text("People")
      expect(f("#breadcrumbs")).not_to include_text("Courses")
      expect(f('.users-list')).to include_text("Test User")

      f('#section-tabs .courses').click
    end

  end



  it "should not show the people tab without permission" do
    @account.role_overrides.create! :role => admin_role, :permission => 'read_roster', :enabled => false

    get "/accounts/#{@account.id}"

    expect(f("#left-side #section-tabs")).not_to include_text("People")
  end

  it "should not show the create users button for non-root acocunts" do
    sub_account = Account.create!(:name => "sub", :parent_account => @account)

    get "/accounts/#{sub_account.id}/users"

    expect(f("#content")).not_to contain_css('button.add_user')
  end

  it "should be able to create users" do
    get "/accounts/#{@account.id}/users"

    f('button.add_user').click

    name = 'Test User'
    f('input.user_name').send_keys(name)
    wait_for_ajaximations
    sortable_name = driver.execute_script("return $('input.user_sortable_name').val();")
    expect(sortable_name).to eq "User, Test"

    email = 'someemail@example.com'
    f('input.user_email').send_keys(email)

    f('.ReactModalPortal button[type="submit"]').click
    wait_for_ajaximations

    new_pseudonym = Pseudonym.where(:unique_id => email).first
    expect(new_pseudonym.user.name).to eq name

    # should refresh the users list
    rows = get_rows
    expect(rows.count).to eq 2 # the first user is the admin
    new_row = rows.detect{|r| r.text.include?(name)}
    expect(new_row).to include_text(email)
  end

  it "should be able to create users with confirmation disabled", priority: "1", test_id: 3399311 do
    name = 'Confirmation Disabled'
    get "/accounts/#{@account.id}/users"

    f('button.add_user').click
    f('input.user_name').send_keys(name)
    wait_for_ajaximations

    email = 'someemail@example.com'
    f('input.user_email').send_keys(email)

    input = f('input.user_send_confirmation')
    move_to_click("label[for=#{input['id']}]")

    f('.ReactModalPortal button[type="submit"]').click
    wait_for_ajaximations

    new_pseudonym = Pseudonym.where(:unique_id => email).first
    expect(new_pseudonym.user.name).to eq name
  end

  it "should bring up user page when clicking name", priority: "1", test_id: 3399648 do
    page_user = user_with_pseudonym(:account => @account, :name => "User Page")
    get "/accounts/#{@account.id}/users"

    ff('.userUrl')[1].click
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
    expect(f(".users-list")).to_not include_text("Test User O")
    expect(f("#content")).not_to contain_css('button[title="Previous Page"]')

    f('button[title="Next Page"]').click
    wait_for_ajaximations

    expect(get_rows.count).to eq 12
    expect(get_rows.first).to include_text("Test User O")
    expect(get_rows.last).to include_text("Test User Z")
    expect(f(".users-list")).not_to include_text("Test User A")
    expect(f("#content")).to contain_css('button[title="Previous Page"]')
    expect(f("#content")).not_to contain_css('button[title="Next Page"]')
  end

  it "should search by name" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}/users"

    f('.user_search_bar input[type=search]').send_keys('search')

    expect(f('.users-list')).not_to contain_jqcss('div[role=row]:nth-child(2)')
    rows = get_rows
    expect(rows.count).to eq 1
    expect(rows.first).to include_text(match_user.name)
  end

  it "should search but not find bogus user", priority: "1", test_id: 3399649 do
    bogus = 'jtsdumbthing'
    get "/accounts/#{@account.id}/users"

    f('.user_search_bar input[type=search]').send_keys(bogus)

    rows = get_rows
    expect(rows.first).not_to include_text(bogus)
  end

  it "should link to the user avatar page" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}/users"

    f('#peopleOptionsBtn').click
    f('#manageStudentsLink').click

    expect(driver.current_url).to include("/accounts/#{@account.id}/avatars")
  end

  it "should link to the user group page" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}/users"

    f('#peopleOptionsBtn').click
    f('#viewUserGroupLink').click

    expect(driver.current_url).to include("/accounts/#{@account.id}/groups")
  end

end
