require File.expand_path(File.dirname(__FILE__) + '/common')

TEST_FILE_UUIDS = { "testfile1.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
                "testfile1copy.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
                    "testfile2.txt" => "5d714eca-2cff-4737-8604-45ca098165cc",
                    "testfile3.txt" => "72476b31-58ab-48f5-9548-a50afe2a2fe3",
                    "testfile4.txt" => "38f6efa6-aff0-4832-940e-b6f88a655779" }

shared_examples_for "file uploads selenium tests" do
  it_should_behave_like "forked server selenium tests"
  
  append_after(:all) do
    Setting.remove("file_storage_test_override")
  end

  it "should upload a file on the discussions page" do
    # set up basic user with enrollment
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    login_as( username, password )

    first_time = true    
    # try with three files. the first two are identical, so our md5-based single-instance-storing on s3 should not break.
    ["testfile1.txt", "testfile1copy.txt", "testfile2.txt", "testfile3.txt"].each do |filename|
      # go to our new course's discussion page
      get "/courses/#{e.course_id}/discussion_topics"

      # start a new topic and prepare for new file
      driver.execute_script <<-JS
        $('.add_topic_link:first').click();
        $('#editor_tabs ul li:eq(1) a').click();
      JS
      
      keep_trying { driver.find_element(:css, '#tree1 .folder') }
      driver.find_element(:css, '#tree1 .folder').text.should eql("course files")
      no_files = driver.execute_script("return $('#tree1 .leaf:contains(\"No Files\")')[0]")
      if first_time
        no_files.should_not be_nil
      else
        no_files.should be_nil
      end
      first_time = false

      # upload the file
      driver.find_element(:css, '.upload_new_file_link').click
      driver.find_element(:id, 'attachment_uploaded_data').send_keys("C:\\testfiles\\#{filename}")
      driver.find_element(:css, '#sidebar_upload_file_form button').click
      keep_trying { driver.execute_script("return $('#tree1 .leaf:contains(#{filename})').length") > 0 }
      
      # let's go check out if the file is in the files controller
      get "/courses/#{e.course_id}/files"
      keep_trying { driver.execute_script("return $('a:contains(#{filename})')[0]") }
      
      # check out the file content, make sure it's good
      get "/courses/#{e.course_id}/files/#{Attachment.last.id}/download?wrap=1"
      driver.switch_to.frame('file_content')
      driver.page_source.should match TEST_FILE_UUIDS[filename]
      driver.switch_to.default_content
    end
  end

  it "should upload a file on the homework submissions page" do
    # set up basic objects
    t = user_with_pseudonym :active_user => true,
                            :username => "teacher@example.com",
                            :password => "asdfasdf"
    t.save!
    s = user_with_pseudonym :active_user => true,
                            :username => "student@example.com",
                            :password => "asdfasdf"
    s.save!
    c = course              :active_course => true
    c.enroll_teacher(t).accept!
    c.enroll_student(s).accept!
    c.reload
    
    a = c.assignments.create!(:submission_types => "online_upload")
    
    login_as( "student@example.com", "asdfasdf" )
    
    # and attempt some assignment submissions
    ["testfile1.txt", "testfile1copy.txt", "testfile2.txt", "testfile3.txt"].each do |filename|
      # go to our new assignment page
      get "/courses/#{c.id}/assignments/#{a.id}"

      driver.execute_script("$('.submit_assignment_link').click();")
      keep_trying { driver.execute_script("return $('div#submit_assignment')[0].style.display") != "none" }
      driver.find_element(:name, 'attachments[0][uploaded_data]').send_keys("C:\\testfiles\\#{filename}")
      driver.find_element(:css, '#submit_online_upload_form #submit_file_button').click
      keep_trying { driver.page_source =~ /Download #{Regexp.quote(filename)}<\/a>/ }
      link = driver.find_element(:css, "div.details a.forward")
      link.text.should eql("Submission Details")

      link.click
      keep_trying { driver.page_source =~ /Submission Details<\/h2>/ }
      wait_for_dom_ready
      driver.switch_to.frame('preview_frame')
      driver.find_element(:css, '.centered-block .ui-listview .comment_attachment_link').click
      keep_trying { driver.page_source =~ /#{Regexp.quote(TEST_FILE_UUIDS[filename])}/ }
      driver.switch_to.default_content
    end
  end

end

describe "file uploads Windows-Firefox-Local-Tests" do
  it_should_behave_like "file uploads selenium tests"
  prepend_before(:all) {
    Setting.set("file_storage_test_override", "local")
  }
end

describe "file uploads Windows-Firefox-S3-Tests" do
  it_should_behave_like "file uploads selenium tests"
  prepend_before(:all) {
    Setting.set("file_storage_test_override", "s3")
  }
end
