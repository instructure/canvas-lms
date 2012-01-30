require File.expand_path(File.dirname(__FILE__) + '/common')

describe "main links tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
  end

  def find_link(link_holder_css, link_text)
    link_section = driver.find_element(:css, link_holder_css)
    link_element = link_section.find_element(:link, link_text)
    link_element
  end

  describe "right side links" do

    it "should navigate user to conversations page after inbox link is clicked" do
      link = find_link('#identity', 'Inbox')
      validate_link(link, 'Conversations')
    end

    it "should navigate user to user profile page after profile link is clicked" do
      link = find_link('#identity', 'Profile')
      validate_link(link, 'profile')
    end
  end

  describe "left side links" do

    it "should navigate user to main page after canvas logo link is clicked" do
      driver.find_element(:id, 'header-logo')
      expect_new_page_load { driver.find_element(:id, 'header-logo').click }
      driver.current_url.should == driver.find_element(:id, 'header-logo').attribute('href')
    end

    it "should navigate user to assignments page after assignments link is clicked" do
      link = find_link('#menu', 'Assignments')
      validate_link(link, 'Assignments')
    end

    it "should navigate user to gradebook page after grades link is clicked" do
      link = find_link('#menu', 'Grades')
      validate_link(link, 'Grades')
    end

    it "should navigate user to the calendar page after calender link is clicked" do
      link = find_link('#menu', 'Calendar')
      validate_link(link, 'My Calendar')
    end
  end
end