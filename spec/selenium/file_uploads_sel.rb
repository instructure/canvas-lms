require File.expand_path(File.dirname(__FILE__) + '/common')

TEST_FILE_UUIDS = { "testfile1.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
                "testfile1copy.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
                    "testfile2.txt" => "5d714eca-2cff-4737-8604-45ca098165cc",
                    "testfile3.txt" => "72476b31-58ab-48f5-9548-a50afe2a2fe3",
                    "testfile4.txt" => "38f6efa6-aff0-4832-940e-b6f88a655779" }

shared_examples_for "file uploads selenium tests" do
  it_should_behave_like "all selenium tests"
  
  append_after(:all) do
    Setting.remove("file_storage_test_override")
  end

  it "should upload a file on the discussions page" do
    # set up basic objects
    u = user_with_pseudonym :active_user => true,
                            :username => "nobody@example.com",
                            :password => "asdfasdf"
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!

    # log out (just in case) and log in
    page.open "/logout"
    page.type "pseudonym_session_unique_id", "nobody@example.com"
    page.type "pseudonym_session_password", "asdfasdf"
    page.click "//button[@type='submit']"
    page.wait_for_page_to_load "30000"

    # go to our new course's discussion page
    page.open "/courses/#{e.course_id}/discussion_topics"
    
    # start a new topic and prepare for new file
    page.click "link=Start a New Topic"
    page.click "//div[@id='editor_tabs']/ul/li[2]/a"
    !60.times{ break if (page.is_text_present("course files") rescue false); sleep 1 }
    page.is_text_present("course files").should be_true
    page.is_text_present("No Files").should be_true
    
    # try with three files. the first two are identical, so our md5-based single-instance-storing on s3 should not break.
    ["testfile1.txt", "testfile1copy.txt", "testfile2.txt", "testfile3.txt"].each do |filename|
      # upload the file
      page.click "link=Upload a new file"
      page.type "attachment_uploaded_data", "C:\\testfiles\\#{filename}"
      page.click "//form[@id='sidebar_upload_file_form']//button"
      !60.times{ break if (page.is_text_present(filename) rescue false); sleep 1 }
      page.is_text_present(filename).should be_true
      
      # let's go check out if the file is in the files controller
      page.click "link=Files"
      page.wait_for_element "link=#{filename}"
      
      # check out the file content, make sure it's good
      page.open "/courses/#{e.course_id}/files/#{Attachment.last.id}/download?wrap=1"
      page.wait_for_element "//iframe[@id='file_content']"
      page.select_frame "//iframe[@id='file_content']"
      !60.times{ break if (page.is_text_present(TEST_FILE_UUIDS[filename]) rescue false); sleep 1 }
      page.is_text_present(TEST_FILE_UUIDS[filename]).should be_true
      page.select_frame "relative=top"
      
      # make sure the discussion page has files now.
      page.open "/courses/#{e.course_id}/discussion_topics"
      page.wait_for_element "link=Start a New Topic"
      page.click "link=Start a New Topic"
      page.click "//div[@id='editor_tabs']/ul/li[2]/a"
      !60.times{ break if (page.is_text_present("course files") rescue false); sleep 1 }
      page.is_text_present("course files").should be_true
      page.is_text_present("No Files").should be_false
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
    
    a = Assignment.new(:submission_types => "online_upload", :context => c)
    a.save!

    # log out (just in case) and log in
    page.open "/logout"
    page.type "pseudonym_session_unique_id", "student@example.com"
    page.type "pseudonym_session_password", "asdfasdf"
    page.click "//button[@type='submit']"
    page.wait_for_page_to_load "30000"
    
    # go to our new assignment page
    page.open "/courses/#{c.id}/assignments/#{a.id}"
    sleep 5
    # and attempt some assignment submissions
    first = true

    ["testfile1.txt", "testfile1copy.txt", "testfile2.txt", "testfile3.txt"].each do |filename|
      if first
        page.click "link=Submit Assignment"
        first = false
      else
        page.click "link=Re-Submit Assignment"
      end
      sleep 8
      !60.times{ break if (page.is_element_present("attachments[0][uploaded_data]") rescue false); sleep 1 }
      page.type "attachments[0][uploaded_data]", "C:\\testfiles\\#{filename}"
      page.click "//form[@id='submit_online_upload_form']//button[@id='submit_file_button']"
      page.wait_for_page_to_load "30000"
      sleep 5
      page.click "link=Submission Details"
      page.wait_for_page_to_load "30000"
      sleep 5
      !60.times{ break if (page.is_element_present("//iframe[@id='preview_frame']") rescue false); sleep 1 }
      page.select_frame "//iframe[@id='preview_frame']"
      !60.times{ break if (page.is_element_present("link=#{filename}") rescue false); sleep 1 }
      page.click "link=#{filename}"
      sleep 5
      !60.times{ break if (page.is_text_present(TEST_FILE_UUIDS[filename]) rescue false); sleep 1 }
      page.is_text_present(TEST_FILE_UUIDS[filename]).should be_true
      page.select_frame "relative=top"
    end
  end

end

describe "file uploads Windows-Firefox-Local-Tests" do
  it_should_behave_like "file uploads selenium tests"
  before(:all) {
    @selenium_driver = setup_selenium "Windows-Firefox"
    Setting.set("file_storage_test_override", "local")
  }
end

describe "file uploads Windows-Firefox-S3-Tests" do
  it_should_behave_like "file uploads selenium tests"
  prepend_before(:all) {
    @selenium_driver = setup_selenium "Windows-Firefox"
    Setting.set("file_storage_test_override", "s3")
  }
end
