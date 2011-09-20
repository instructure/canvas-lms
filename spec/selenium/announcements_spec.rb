require File.expand_path(File.dirname(__FILE__) + '/common')

describe "announcements selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    stub_kaltura
  end

  it "should not show JSON when loading more assignments via pageless" do
    course_with_student_logged_in
    
    50.times { @course.announcements.create!(:title => 'Hi there!', :message => 'Announcement time!') }
    get "/courses/#{@course.id}/announcements"
    
    start = driver.find_elements(:css, "#topic_list .topic").length
    driver.execute_script('window.scrollTo(0, 100000)')
    keep_trying_until { driver.find_elements(:css, "#topic_list .topic").length > start }
    
    driver.find_element(:id, "topic_list").text.should_not match /discussion_topic/
  end

  def clear_rce()
    #clear rce, because a second hyperlinked content item can not be added
    #after the first
    driver.find_element(:link, 'Switch Views').click
    driver.find_element(:id, 'topic_content_topic_new').clear
    driver.find_element(:link, 'Switch Views').click
  end

  it "should create an announcement" do
    course_with_teacher_logged_in

    #create test assignment
    assignment_name = 'first assignment'
    @assignment = @course.assignments.create(:name => assignment_name)
    #create test quiz
    quiz_title = "My Quiz"
    q = @course.quizzes.build(:title => quiz_title, :description => "Sup")
    q.generate_quiz_data
    q.published_at = Time.now
    q.workflow_state = 'available'
    q.save!

    get "/courses/#{@course.id}/announcements"

    #start creating announcement  
    driver.find_element(:css, '.add_topic_link').click
    topic_title = driver.find_element(:css, '.add_topic_form_new input[name="discussion_topic[title]"]')
    topic_title.clear
    topic_title.send_keys "First Announcement"
    topic = driver.find_element(:id, 'topic_content_topic_new_parent')
    topic.find_element(:css, '.mceIcon.mce_bold').click
    topic.find_element(:css, '.mceIcon.mce_italic').click
    tiny_frame = wait_for_tiny(driver.find_element(:css, 'textarea.topic_content'))
    #check typing in rce
    first_text = 'Hi, this is my first announcement'
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys(first_text)
      driver.find_element(:id, 'tinymce').text.include?(first_text).should be_true
    end
    topic.find_element(:css, '.mceIcon.mce_bold').click
    topic.find_element(:css, '.mceIcon.mce_italic').click
    driver.find_element(:css, '.switch_topic_views_link').click
    driver.execute_script("return $('#topic_content_topic_new').val()").
      include?('<p><strong><em>').should be_true
    driver.find_element(:css, '.switch_topic_views_link').click
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').text.include?('<p>').should be_false
    end

    tabs = driver.find_element(:id, 'editor_tabs')
    accordion = tabs.find_element(:id, 'pages_accordion')

    #check assigment accordion
    accordion.find_element(:link, I18n.t('links_to.assignments','Assignments')).click
    keep_trying_until{ accordion.find_element(:link, assignment_name).displayed? }
    accordion.find_element(:link, assignment_name).click
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').text.include?(assignment_name).should be_true
    end
    clear_rce

    # add quiz to rce
    accordion.find_element(:link, I18n.t('links_to.quizzes','Quizzes')).click
    keep_trying_until{ accordion.find_element(:link, quiz_title).displayed? }
    accordion.find_element(:link, quiz_title).click
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').text.include?(quiz_title).should be_true
    end
    clear_rce

    #upload file and add to rce
    tabs.find_element(:css, 'a[href="#editor_tabs_2"]').click
    tabs.find_element(:css, '.upload_new_file_link').click
    filename, fullpath, data = get_file("testfile1.txt")
    tabs.find_element(:css, '#sidebar_upload_file_form input[name="attachment[uploaded_data]"]').send_keys(fullpath)
    tabs.find_element(:id, 'sidebar_upload_file_form').submit
    keep_trying_until { driver.find_element(:id, 'sidebar_upload_file_form').displayed? == false }
    tabs.find_element(:css, '#tree1 .folder .name').click
    keep_trying_until{ tabs.find_element(:css, '#tree1 .folder .file').
      text.should eql(filename) }
    in_frame tiny_frame["id"] do
        driver.find_element(:id, 'tinymce').text.include?(filename).should be_true
    end
    clear_rce

    #upload image and add to rce
    tabs.find_element(:css, 'a[href="#editor_tabs_3"]').click
    tabs.find_element(:css, ".upload_new_image_link").click
    filename, fullpath, data = get_file("graded.png")
    driver.
      find_element(:css, '#sidebar_upload_image_form input[name="attachment[uploaded_data]"]').send_keys(fullpath)
    driver.find_element(:id, 'sidebar_upload_image_form').submit
    in_frame tiny_frame["id"] do
        keep_trying_until{ driver.find_element(:css, '#tinymce img').displayed?.should be_true }
    end
    clear_rce


    #add math equation to rce
    driver.find_element(:css, '#topic_content_topic_new_instructure_equation > img.mceIcon').click
    wait_for_animations
    equation_dialog = driver.find_element(:id, 'instructure_equation_prompt') 
    misc_tab = driver.find_element(:css, '.mathquill-tab-bar > li:last-child a')
    driver.action.move_to(misc_tab).perform
    driver.find_element(:css, '#Misc_tab li:nth-child(35) a').click
    basic_tab = driver.find_element(:css, '.mathquill-tab-bar > li:first-child a')
    driver.action.move_to(basic_tab).perform
    driver.find_element(:css, '#Basic_tab li:nth-child(27) a').click
    driver.find_element(:id, 'instructure_equation_prompt_form').submit
    in_frame tiny_frame["id"] do
        flickr_img = driver.find_element(:css, '#tinymce img').displayed?.should be_true
    end

    #add image from flickr to rce
    driver.find_element(:css, '.mce_instructure_embed').click
    driver.find_element(:css, '.flickr_search_link').click
    driver.find_element(:css, '#image_search_form > input').send_keys('angel')
    driver.find_element(:id, 'image_search_form').submit
    driver.find_element(:css, '.image_link').click
    flickr_img_url = ''
    in_frame tiny_frame["id"] do
        flickr_img = driver.find_element(:css, '#tinymce img')
        flickr_img.displayed?.should be_true
        flickr_img_url = flickr_img.attribute('src')
    end

    #make sure record video dialog appears
    driver.find_element(:css, '.mce_instructure_record').click
    keep_trying_until{ driver.find_element(:id, 'record_media_tab').should be_displayed }
    driver.find_element(:css, '#ui-dialog-title-media_comment_dialog + a .ui-icon-closethick').click
    driver.find_element(:id, 'media_comment_dialog').should_not be_displayed

    #make sure announcement is created
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys(first_text)
    end 
    driver.find_element(:css, '.add_topic_form_new').submit
    wait_for_animations
    driver.find_element(:link, "First Announcement").should be_displayed
    driver.find_element(:css, 'img[src="' + flickr_img_url + '"]').should be_displayed

  end

  it "should have a teacher add a new entry to its own announcement" do
    course_with_teacher_logged_in
    @context = @course
    announcement_model
    get "/courses/#{@course.id}/announcements"

    driver.find_element(:css, '.content .replies').click
    driver.find_element(:css, '#content .add_entry_link').click
    entry_text = 'new entry text'
    tiny_frame = wait_for_tiny(driver.find_element(:css, 'textarea.entry_content'))
    in_frame tiny_frame["id"] do
      driver.find_element(:id, 'tinymce').send_keys(entry_text)
    end
    driver.find_element(:id, 'add_entry_form_entry_new').submit
    wait_for_ajax_requests
    wait_for_animations
    driver.find_element(:css, '#entry_list .discussion_entry .content').should include_text(entry_text)
    driver.find_element(:css, '#left-side .announcements').click
    driver.find_element(:css, '#topic_list .replies').should include_text('1')
  end


  it "should add an external feed to announcements" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/announcements"

    #add external feed to announcements
    feed_name = 'http://www.google.com'
    driver.find_element(:css, '.add_external_feed_link').click
    feed_form = driver.find_element(:id, 'add_external_feed_form')
    feed_form.find_element(:id, 'external_feed_url').send_keys(feed_name)
    unless feed_form.find_element(:id, 'external_feed_header_match').displayed?
      feed_form.find_element(:id, 'external_feed_add_header_match').click
    end
    feed_form.find_element(:id, 'external_feed_header_match').send_keys('blah')
    feed_form.submit
    wait_for_ajaximations

    #delete external feed
    driver.find_element(:link, feed_name).should be_displayed
    driver.find_element(:css, '#external_feeds li:nth-child(2) .delete_feed_link').click
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.accept
    wait_for_ajaximations
    element_exists(:link, feed_name).should be_false
    ExternalFeed.count.should eql(0)

    #cancel while adding an external feed
    driver.find_element(:css, '.add_external_feed_link').click
    feed_form.find_element(:id, 'external_feed_url').send_keys('http://www.yahoo.com')
    feed_form.find_element(:id, 'external_feed_header_match').send_keys('more blah')
    feed_form.find_element(:css, '#add_external_feed_form .cancel_button').click
    wait_for_animations
    driver.find_element(:id,'add_external_feed_form').should_not be_displayed

  end

end
