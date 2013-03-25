require File.expand_path(File.dirname(__FILE__) + '/../..//helpers/shared_user_methods')


  def should_add_a_new_user
    course_with_admin_logged_in
    get url
    user = add_user(opts)
    refresh_page #we need to refresh the page to see the user
    f("#user_#{user.id}").should be_displayed
    f("#user_#{user.id}").should include_text(opts[:name])
  end
