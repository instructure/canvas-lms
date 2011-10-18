require File.expand_path(File.dirname(__FILE__) + '/common')

describe "people" do
  it_should_behave_like "in-process server selenium tests"

  it "should navigate to registered services on profile page" do
    course_with_teacher_logged_in
    
    get "/courses/#{@course.id}/users"
    
    driver.find_element(:link, I18n.t('links.view_services','View Registered Services')).click
    driver.find_element(:link, I18n.t('links.link_service', 'Link web services to my account')).click
    driver.find_element(:id, 'unregistered_services').should be_displayed

  end
end
