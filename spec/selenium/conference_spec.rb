require File.expand_path(File.dirname(__FILE__) + "/common")

describe "web conference" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    PluginSetting.create!(:name => "dim_dim", :settings =>
        {"domain" => "dimdim.instructure.com"})
    get "/courses/#{@course.id}/conferences"
  end

  it "should create a web conference" do
    conference_title = 'new conference'
    driver.find_element(:link, 'Make a New Conference').click

    driver.find_element(:id, 'web_conference_title').clear
    driver.find_element(:id, 'web_conference_title').send_keys(conference_title)
    submit_form('#add_conference_form')
    wait_for_ajaximations
    driver.find_element(:link, conference_title).click
    driver.find_element(:id, 'content').text.include?(conference_title).should be_true

  end

  it "should cancel creating a web conference" do
    conference_title = 'new conference'
    driver.find_element(:link, 'Make a New Conference').click
    driver.find_element(:id, 'web_conference_title').clear
    driver.find_element(:id, 'web_conference_title').send_keys(conference_title)
    driver.find_element(:css, '#add_conference_form button.cancel_button').click
    wait_for_animations
    driver.find_element(:css, '#add_conference_form div.header').text.include?('Start').should be_false
  end
end
