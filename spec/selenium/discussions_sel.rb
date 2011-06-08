require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "discussions selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should not record a javascript error when creating the first topic" do
    course_with_teacher_logged_in
    
    get "/courses/#{@course.id}/discussion_topics"
    driver.find_element(:css, ".add_topic_link").click
    driver.execute_script("return INST.errorCount;").should == 0
    
    form = driver.find_element(:id, 'add_topic_form_topic_new')
    
    tiny_frame = wait_for_tiny(form.find_element(:css, '.content_box'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys('This is the discussion description.')
    end
    form.find_element(:id, "discussion_topic_title").send_keys("This is my test title")
    form.find_element(:css, ".submit_button").click
    keep_trying_until { DiscussionTopic.count.should == 1 }

    find_all_with_jquery(".add_topic_form_new:visible").length.should == 0
    driver.execute_script("return INST.errorCount;").should == 0
  end
end

describe "course Windows-Firefox-Tests" do
  it_should_behave_like "discussions selenium tests"
end
