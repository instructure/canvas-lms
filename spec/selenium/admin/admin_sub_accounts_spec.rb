require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin sub accounts" do
  include_examples "in-process server selenium tests"
  DEFAULT_ACCOUNT_ID = Account.default.id

  def create_sub_account(name = 'sub account', number_to_create = 1, parent_account = Account.default)
    created_sub_accounts = []
    number_to_create.times do |i|
      sub_account = Account.create(:name => name + " #{i}", :parent_account => parent_account)
      created_sub_accounts.push(sub_account)
    end
    created_sub_accounts.count == 1 ? created_sub_accounts[0] : created_sub_accounts
  end

  def click_account_action_link(account_id, action_link_css)
    f("#account_#{account_id} #{action_link_css}").click
  end

  def create_sub_account_and_go
    sub_account = create_sub_account
    get "/accounts/#{DEFAULT_ACCOUNT_ID}/sub_accounts"
    sub_account
  end

  def edit_account_info(input_css, text_to_input)
    new_account_input = f(input_css)
    new_account_input.send_keys(text_to_input)
    new_account_input.send_keys(:return)
    wait_for_ajaximations
  end

  before (:each) do
    course_with_admin_logged_in
  end

  it "should create a new sub account" do
    get "/accounts/#{DEFAULT_ACCOUNT_ID}/sub_accounts"
    new_account_name = 'new sub account'
    click_account_action_link(DEFAULT_ACCOUNT_ID, '.add_sub_account_link')
    edit_account_info('#new_account #account_name', new_account_name)
    sub_accounts = ff('.sub_accounts .sub_account')
    sub_accounts.count.should == 1
    sub_accounts[0].should include_text(new_account_name)
    Account.last.name.should == new_account_name
  end

  it "should delete a sub account" do
    sub_account = create_sub_account_and_go
    expect {
      click_account_action_link(sub_account.id, '.delete_account_link')
      driver.switch_to.alert.accept
      wait_for_ajaximations
    }.to change(Account.default.sub_accounts, :count).by(-1)
    sub_accounts = ff('.sub_accounts .sub_account')
    sub_accounts.each { |account| account.should_not include_text(sub_account.name) }
  end

  it "should edit a sub account" do
    edit_name = 'edited sub account'
    sub_account = create_sub_account_and_go
    click_account_action_link(sub_account.id, '.edit_account_link')
    edit_account_info("#account_#{sub_account.id} #account_name", edit_name)
    f("#account_#{sub_account.id}").should include_text(edit_name)
    Account.where(id: sub_account).first.name.should == edit_name
  end

  it "should validate sub account count on main account" do
    get "/accounts/#{DEFAULT_ACCOUNT_ID}/sub_accounts"
    f('.sub_accounts_count').should_not be_displayed
    create_sub_account
    refresh_page # to make new sub account show up
    f('.sub_accounts_count').text.should == "1 Sub-Account"
  end

  it "should be able to nest sub accounts" do
    expected_second_sub_account_name = 'second sub account 0'
    first_sub = create_sub_account
    second_sub = create_sub_account('second sub account', 1, first_sub)
    sub_accounts = [first_sub, second_sub]
    Account.default.sub_accounts.each_with_index { |account, i| account.name.should == sub_accounts[i].name }
    get "/accounts/#{DEFAULT_ACCOUNT_ID}/sub_accounts"
    first_sub.sub_accounts.first.name.should == expected_second_sub_account_name
    first_sub_account = f("#account_#{first_sub.id}")
    first_sub_account.find_element(:css, ".sub_accounts_count").text.should == '1 Sub-Account'
    first_sub_account.find_element(:css, ".sub_account").should include_text(second_sub.name)
  end

  it "should hide sub accounts and re-expand them" do
    def check_sub_accounts(displayed = true)
      sub_accounts = ff('.sub_accounts .sub_account')
      displayed ? sub_accounts.each { |account| account.should be_displayed } : sub_accounts.each { |account| account.should_not be_displayed }
    end

    create_sub_account('sub account', 5)
    get "/accounts/#{DEFAULT_ACCOUNT_ID}/sub_accounts"
    check_sub_accounts
    click_account_action_link(DEFAULT_ACCOUNT_ID, '.collapse_sub_accounts_link')
    wait_for_ajaximations
    check_sub_accounts(false)
    click_account_action_link(DEFAULT_ACCOUNT_ID, '.expand_sub_accounts_link')
    wait_for_ajaximations
    check_sub_accounts
  end

  it "should validate course count for a sub account" do
    def validate_course_count(account_id, count_text)
      f("#account_#{account_id} .courses_count").text.should == count_text
    end

    added_courses_count = 3
    get "/accounts/#{DEFAULT_ACCOUNT_ID}/sub_accounts"

    validate_course_count(DEFAULT_ACCOUNT_ID, '1 Course') #make sure default account was setup correctly
    sub_account = create_sub_account('add courses to me')
    added_courses_count.times { Course.create!(:account => sub_account) }
    refresh_page # to make new account with courses show up
    validate_course_count(sub_account.id, '3 Courses')
  end

  it "should validate that you can't delete a sub account with courses in it" do
    get "/accounts/#{DEFAULT_ACCOUNT_ID}/sub_accounts"
    click_account_action_link(DEFAULT_ACCOUNT_ID, '.cant_delete_account_link')
    driver.switch_to.alert.text.should == "You can't delete a sub-account that has courses in it"
    driver.switch_to.alert.accept
    Account.default.workflow_state.should == 'active'
  end
end