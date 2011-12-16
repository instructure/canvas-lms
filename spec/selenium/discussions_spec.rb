require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "discussions selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should load both topics and images via pageless without conflict" do
    course_with_teacher_logged_in

    # create some topics. 11 is enough to trigger pageless with default value
    # of 10 per page
    11.times do |i|
      @course.discussion_topics.create!(:title => "Topic #{i}")
    end

    # create some images
    2.times do |i|
      @attachment = @course.attachments.build
      @attachment.filename = "image#{i}.png"
      @attachment.file_state = 'available'
      @attachment.content_type = 'image/png'
      @attachment.save!
    end

    get "/courses/#{@course.id}/discussion_topics"
    start_topics = driver.find_elements(:css, "#topic_list .topic").length
    start_images = driver.find_elements(:css, ".image_list .img_holder").length

    # go to Images tab to trigger pageless for .image_list
    keep_trying_until {
      driver.find_element(:css, '.add_topic_link').click()
      driver.find_elements(:css, '#editor_tabs .ui-tabs-nav li a').last.should be_displayed
    }
    driver.find_elements(:css, '#editor_tabs .ui-tabs-nav li a').last.click

    # scroll window to trigger pageless for #topic_list
    driver.execute_script('window.scrollTo(0, 100000)')

    # wait till done
    wait_for_ajax_requests
    wait_for_ajaximations

    # check all topics were loaded (11 we created, plus the blank template)
    driver.find_elements(:css, "#topic_list .topic").length.should == 12

    # check images were loaded
    driver.find_elements(:css, ".image_list .img_holder").length.should == 2
  end

  it "should not record a javascript error when creating the first topic" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/discussion_topics"

    form = keep_trying_until {
      driver.find_element(:css, ".add_topic_link").click
      driver.find_element(:id, 'add_topic_form_topic_new')
    }
    driver.execute_script("return INST.errorCount;").should == 0

    form.find_element(:id, "discussion_topic_title").send_keys("This is my test title")
    type_in_tiny '#add_topic_form_topic_new .topic_content', 'This is the discussion description.'

    form.find_element(:css, ".submit_button").click
    wait_for_ajax_requests
    keep_trying_until { DiscussionTopic.count.should == 1 }

    find_all_with_jquery(".add_topic_form_new:visible").length.should == 0
    driver.execute_script("return INST.errorCount;").should == 0
  end

  it "should create a podcast enabled topic" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/discussion_topics"

    form = keep_trying_until {
      driver.find_element(:css, ".add_topic_link").click
      driver.find_element(:id, 'add_topic_form_topic_new')
    }

    form.find_element(:id, "discussion_topic_title").send_keys("This is my test title")
    type_in_tiny '#add_topic_form_topic_new .topic_content', 'This is the discussion description.'

    form.find_element(:css, '.more_options_link').click
    form.find_element(:id, 'discussion_topic_podcast_enabled').click

    form.find_element(:css, ".submit_button").click
    wait_for_ajaximations

    driver.find_element(:css, '.discussion_topic .podcast img').click
    wait_for_animations
    driver.find_element(:css, '#podcast_link_holder .feed').should be_displayed

  end

  it "should display the current username when making a side comment" do
    course_with_teacher_logged_in

    topic = @course.discussion_topics.create!
    entry = topic.discussion_entries.create!

    get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

    form = keep_trying_until {
      find_with_jquery('.communication_sub_message .add_entry_link:visible').click
      find_with_jquery('.add_sub_message_form:visible')
    }

    type_in_tiny '.add_sub_message_form:visible textarea', "My side comment!"
    form.find_element(:css, '.submit_button').click
    wait_for_ajax_requests
    wait_for_animations

    entry.discussion_subentries.should_not be_empty

    find_with_jquery(".communication_sub_message:visible .user_name").text.should == @user.name

  end
end

describe "course Windows-Firefox-Tests" do
  it_should_behave_like "discussions selenium tests"
end
