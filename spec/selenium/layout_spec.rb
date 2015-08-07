require File.expand_path(File.dirname(__FILE__) + '/common')

describe "layout" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_student_logged_in
    @user.update_attribute(:name, "</script><b>evil html & name</b>")
    get "/"
  end

  it "should auto-scroll the sidebar when $.scrollSidebar is called" do
    exec_cs  <<-CS
      $("#content").height(10000)
      $("#right-side").height(5000)
      $.scrollSidebar()
    CS

    rs_wrapper = f('#right-side-wrapper')
    expect(rs_wrapper).not_to have_class 'with-scrolling-right-side'
    expect(rs_wrapper).not_to have_class 'with-sidebar-pinned-to-bottom'

    f('#footer').location_once_scrolled_into_view
    # We sleep here because the window scroll triggers a call to scrollSidebar that might
    # be slightly throttled. We don't want to actually call scrollSidebar() ourselves
    # because that's subverting part of the test. The throttle shouldn't be more than 50ms,
    # so sleeping 100ms should be sufficient for it to fire.
    sleep 0.1
    expect(rs_wrapper).not_to have_class 'with-scrolling-right-side'
    expect(rs_wrapper).to have_class 'with-sidebar-pinned-to-bottom'

    f('#dashboard').location_once_scrolled_into_view
    sleep 0.1
    expect(rs_wrapper).to have_class 'with-scrolling-right-side'
    expect(rs_wrapper).not_to have_class 'with-sidebar-pinned-to-bottom'

    f('#header').location_once_scrolled_into_view
    sleep 0.1
    expect(rs_wrapper).not_to have_class 'with-scrolling-right-side'
    expect(rs_wrapper).not_to have_class 'with-sidebar-pinned-to-bottom'
  end

  it "should have ENV available to the JavaScript from js_env" do
    expect(driver.execute_script("return ENV.current_user_id")).to eq @user.id.to_s
  end

  it "should escape JSON injected directly into the view" do
    expect(driver.execute_script("return ENV.current_user.display_name")).to eq  "</script><b>evil html & name</b>"
  end
end
