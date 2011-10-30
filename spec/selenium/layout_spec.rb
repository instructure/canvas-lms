require File.expand_path(File.dirname(__FILE__) + '/common')

describe "layout selenium tests" do
  it_should_behave_like "in-process server selenium tests"


  it "should auto-scroll the sidebar when $.scrollSidebar is called" do
    course_with_student_logged_in
    get "/"
    driver.execute_script('$("#not_right_side").height(10000)')
    driver.execute_script('$("#right-side-wrapper").height(5000)')
    driver.execute_script('$.scrollSidebar()')
    body = driver.find_element(:tag_name, 'body')
    body.attribute(:class).should_not match /with-scrolling-right-side/
    body.attribute(:class).should_not match /with-sidebar-pinned-to-bottom/

    driver.find_element(:id, 'footer').location_once_scrolled_into_view
    body.attribute(:class).should_not match /with-scrolling-right-side/
    body.attribute(:class).should match /with-sidebar-pinned-to-bottom/

    driver.find_element(:id, 'topic_list').location_once_scrolled_into_view
    body.attribute(:class).should match /with-scrolling-right-side/
    body.attribute(:class).should_not match /with-sidebar-pinned-to-bottom/

    driver.find_element(:id, 'header').location_once_scrolled_into_view
    body.attribute(:class).should_not match /with-scrolling-right-side/
    body.attribute(:class).should_not match /with-sidebar-pinned-to-bottom/
  end
end
