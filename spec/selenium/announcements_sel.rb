require File.expand_path(File.dirname(__FILE__) + '/common')

describe "announcements selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should not show JSON when loading more assignments via pageless" do
    course_with_student_logged_in
    
    50.times { @course.announcements.create!(:title => 'Hi there!', :message => 'Announcement time!') }
    get "/courses/#{@course.id}/announcements"
    
    start = driver.find_elements(:css, "#topic_list .topic").length
    driver.execute_script('window.scrollTo(0, 100000)')
    keep_trying_until { driver.find_elements(:css, "#topic_list .topic").length > start }
    
    driver.find_element(:id, "topic_list").text.should_not match /discussion_topic/
  end
end
