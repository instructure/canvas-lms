require File.expand_path(File.dirname(__FILE__) + '/common')

describe "terms of use test" do
  include_context "in-process server selenium tests"

  before do
    user_with_pseudonym(active_user: true)
  end

  it "should not require a user to accept the terms if they haven't changed", priority: "1", test_id: 268275 do
    login_as
    expect(f('.reaccept_terms')).not_to be_present
  end

  it "should not require a user to accept the terms if already logged in when they change", priority: "2", test_id: 268712 do
    create_session(@pseudonym)
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    get "/"
    expect(f('.reaccept_terms')).not_to be_present
  end

  it "should require a user to accept the terms if they have changed", priority: "1", test_id: 268933 do
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    login_as
    form = f('.reaccept_terms')
    expect(form).to be_present
    expect_new_page_load {
      f('[name="user[terms_of_use]"]').click
      submit_form form
    }
    expect(f('.reaccept_terms')).not_to be_present
  end

  it "should prevent them from using canvas if the terms have changed", priority: "1", test_id: 268934 do
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    login_as
    # try to view a different page
    get "/profile/settings"
    expect(f('.reaccept_terms')).to be_present
  end
end

describe "terms of use SOC2 compliance test" do
  include_context "in-process server selenium tests"

  it "should prevent a user from accessing canvas if they are newly registered/imported after the SOC2 start date and have not yet accepted the terms", priority: "1", test_id: 268935 do

    # Create a user after SOC2 implemented
    after_soc2_start_date = Setting.get('SOC2_start_date', Time.new(2015, 5, 16, 0, 0, 0).utc).to_datetime + 10.days

    Timecop.freeze(after_soc2_start_date) do
      user_with_pseudonym
      @user.register!
    end

    login_as

    # terms page should be displayed
    expect(f('.reaccept_terms')).to be_present

    # try to view a different page, terms page should remain
    get "/profile/settings"
    form = f('.reaccept_terms')
    expect(form).to be_present

    # accept the terms
    expect_new_page_load {
      f('[name="user[terms_of_use]"]').click
      submit_form form
    }

    expect(f('.reaccept_terms')).not_to be_present
  end

  it "should grandfather in previously registered users without prompting them to reaccept the terms", priority: "1", test_id: 268936 do

    # Create a user before SOC2 implemented
    before_soc2_start_date = Setting.get('SOC2_start_date', Time.new(2015, 5, 16, 0, 0, 0).utc).to_datetime - 10.days

    Timecop.freeze(before_soc2_start_date) do
      user_with_pseudonym
      @user.register!
    end

    login_as

    # terms page shouldn't be visible
    expect(f('.reaccept_terms')).not_to be_present

    # view a different page, verify terms page isn't displayed
    get "/profile/settings"
    form = f('.reaccept_terms')
    expect(form).not_to be_present
  end
end
