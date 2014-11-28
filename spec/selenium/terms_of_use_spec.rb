require File.expand_path(File.dirname(__FILE__) + '/common')

describe "terms of use test" do
  include_examples "in-process server selenium tests"

  before do
    user_with_pseudonym(active_user: true)
  end

  it "should not require a user to accept the terms if they haven't changed" do
    login_as
    expect(f('.reaccept_terms')).not_to be_present
  end

  it "should not require a user to accept the terms if already logged in when they change" do
    login_as
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    get "/"
    expect(f('.reaccept_terms')).not_to be_present
  end

  it "should require a user to accept the terms if they have changed" do
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

  it "should prevent them from using canvas if the terms have changed" do
    account = Account.default
    account.settings[:terms_changed_at] = Time.now.utc
    account.save!
    login_as
    # try to view a different page
    get "/profile/settings"
    expect(f('.reaccept_terms')).to be_present
  end
end
