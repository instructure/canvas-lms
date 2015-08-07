require File.expand_path(File.dirname(__FILE__) + '/../..//helpers/shared_user_methods')

shared_examples_for "users basic tests" do
  include_context "in-process server selenium tests"

  it "should add a new user" do
    skip('newly added user in sub account does not show up') if account != Account.default
    course_with_admin_logged_in
    get url
    user = add_user(opts)
    refresh_page #we need to refresh the page to see the user
    expect(f("#user_#{user.id}")).to be_displayed
    expect(f("#user_#{user.id}")).to include_text(opts[:name])
  end
end