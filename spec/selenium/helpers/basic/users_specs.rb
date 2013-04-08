require File.expand_path(File.dirname(__FILE__) + '/../..//helpers/shared_user_methods')

shared_examples_for "users basic tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should add a new user" do
    pending('newly added user in sub account does not show up') if account != Account.default
    course_with_admin_logged_in
    get url
    user = add_user(opts)
    refresh_page #we need to refresh the page to see the user
    f("#user_#{user.id}").should be_displayed
    f("#user_#{user.id}").should include_text(opts[:name])
  end
end