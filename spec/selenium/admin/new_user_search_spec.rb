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

  def click_tab
    ff(".react-tabs > ul li").detect{|tab| tab.text.include?("People")}.click
    wait_for_ajaximations
  end

  it "should not show the people tab without permission" do
    @account.role_overrides.create! :role => admin_role, :permission => 'read_roster', :enabled => false

    get "/accounts/#{@account.id}"

    expect(f(".react-tabs > ul")).to_not include_text("People")
  end

  it "should not show the create users button for non-root acocunts" do
    sub_account = Account.create!(:name => "sub", :parent_account => @account)

    get "/accounts/#{sub_account.id}"

    click_tab

    expect(f("#content")).not_to contain_css('button.add_user')
  end

  it "should be able to create users" do
    get "/accounts/#{@account.id}"

    click_tab

    f('button.add_user').click

    name = 'Test User'
    f('input.user_name').send_keys(name)
    wait_for_ajaximations
    sortable_name = driver.execute_script("return $('input.user_sortable_name').val();")
    expect(sortable_name).to eq "User, Test"

    email = 'someemail@example.com'
    f('input.user_email').send_keys(email)

    input = f('input.user_send_confirmation')
    move_to_click("label[for=#{input['id']}]")

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

  it "should paginate" do
    10.times do |x|
      user_with_pseudonym(:account => @account, :name => "Test User #{x + 1}")
    end

    get "/accounts/#{@account.id}"
    click_tab

    expect(get_rows.count).to eq 10

    f(".load_more").click
    wait_for_ajaximations

    expect(get_rows.count).to eq 11
    expect(f("#content")).not_to contain_css(".load_more")
  end

  it "should search by name" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}"
    click_tab

    f('.user_search_bar input[type=text]').send_keys('search')
    f('.user_search_bar button').click
    wait_for_ajaximations

    rows = get_rows
    expect(rows.count).to eq 1
    expect(rows.first).to include_text(match_user.name)
  end

  it "should link to the user avatar page" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}"
    click_tab

    f('#peopleOptionsBtn').click
    f('#manageStudentsLink').click

    expect(driver.current_url).to include("/accounts/#{@account.id}/avatars")
  end

  it "should link to the user group page" do
    match_user = user_with_pseudonym(:account => @account, :name => "user with a search term")
    user_with_pseudonym(:account => @account, :name => "diffrient user")

    get "/accounts/#{@account.id}"
    click_tab

    f('#peopleOptionsBtn').click
    f('#viewUserGroupLink').click

    expect(driver.current_url).to include("/accounts/#{@account.id}/groups")
  end
end
