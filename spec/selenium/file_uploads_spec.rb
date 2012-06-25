require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "file uploads selenium tests" do
  it_should_behave_like "forked server selenium tests"

  append_after(:all) do
    Setting.remove("file_storage_test_override")
  end

  before (:each) do
    @password = "asdfasdf"
    @teacher = user_with_pseudonym :active_user => true,
                                   :username => "teacher@example.com",
                                   :password => @password
    @teacher.save!

    @student = user_with_pseudonym :active_user => true,
                                   :username => "student@example.com",
                                   :password => @password
    @student.save!

    @course = course :active_course => true
    @course.enroll_teacher(@teacher).accept!
    @course.enroll_student(@student).accept!
    @course.reload
  end

  it "should upload a file on the content import page" do
    skip_if_ie("s3 test fails due to javascript error")
    login_as(@teacher.email, @password)

    get "/courses/#{@course.id}/imports/migrate"

    filename, fullpath, data = get_file("testfile5.zip")

    keep_trying_until { fj("#choose_migration_system").should be_displayed }
    click_option('#choose_migration_system', 'common_cartridge_importer', :value)
    driver.find_element(:css, '#config_options').find_element(:name, 'export_file').send_keys(fullpath)
    submit_form('#config_options')
    wait_for_ajax_requests
    keep_trying_until { driver.find_element(:id, 'file_uploaded').should be_displayed }

    ContentMigration.for_context(@course).count.should == 1
    cm = ContentMigration.for_context(@course).first
    cm.attachment.should_not be_nil
    # these tests run in the forked server since we're switching file storage
    # type, so we can't just grab the attachment contents here to examine them,
    # unfortunately.
  end

  it "should upload a file on the homework submissions page, even over quota" do
    pending('failing with unexpected nil - test needs a rewrite')
    a = @course.assignments.create!(:submission_types => "online_upload")

    login_as(@student.email, @password)
    @student.storage_quota = 1
    @student.save

    # and attempt some assignment submissions
    ["testfile1.txt", "testfile1copy.txt", "testfile2.txt", "testfile3.txt"].each do |orig_filename|
      filename, fullpath, data = get_file(orig_filename)

      # go to our new assignment page
      get "/courses/#{@course.id}/assignments/#{a.id}"

      driver.execute_script("$('.submit_assignment_link').click();")
      keep_trying_until { driver.execute_script("return $('div#submit_assignment')[0].style.display") != "none" }
      driver.find_element(:name, 'attachments[0][uploaded_data]').send_keys(fullpath)
      submit_form('#submit_online_upload_form')
      keep_trying_until { driver.page_source =~ /Download #{Regexp.quote(filename)}<\/a>/ }
      link = driver.find_element(:css, "div.details a.forward")
      link.text.should eql("Submission Details")

      expect_new_page_load { link.click }
      keep_trying_until { driver.page_source =~ /Submission Details<\/h2>/ }
      in_frame('preview_frame') do
        driver.find_element(:css, '.centered-block .ui-listview .comment_attachment_link').click
        wait_for_ajax_requests
        keep_trying_until { driver.page_source =~ /#{Regexp.quote(data)}/ }
      end
    end
  end
end

describe "file uploads local tests" do
  it_should_behave_like "file uploads selenium tests"
  prepend_before (:each) do
    Setting.set("file_storage_test_override", "local")
  end
  prepend_before (:all) do
    Setting.set("file_storage_test_override", "local")
  end

  it "should upload a file on the discussions page" do
    pending("intermittently fails")
    # set up basic user with enrollment
    login_as(@teacher.email, @password)

    first_time = true
    # try with three files. the first two are identical, so our md5-based single-instance-storing on s3 should not break.
    ["testfile1.txt", "testfile1copy.txt", "testfile2.txt", "testfile3.txt"].each do |orig_filename|
      filename, fullpath, data = get_file(orig_filename)

      # go to our new course's discussion page
      get "/courses/#{@course.id}/discussion_topics"

      # start a new topic and prepare for new file
      driver.execute_script <<-JS
        $('.add_topic_link:first').click();
        $('#editor_tabs ul li:eq(1) a').click();
      JS
      wait_for_ajax_requests

      driver.find_element(:css, '#tree1 .folder').text.should eql("course files")
      driver.find_element(:css, '#tree1 .folder .sign').click
      # work around bizarre bug where the click above doesn't register the first time
      # when testing firefox on windows xp WITHOUT firebug installed. (works with firebug enabled!)
      sign = find_with_jquery("#tree1 .folder .sign.minus")
      sign.click if sign != nil

      wait_for_ajax_requests

      files = driver.find_elements(:css, '#tree1 .folder .file')
      if first_time
        files.should be_empty
      else
        files.should_not be_empty
      end
      first_time = false

      # upload the file
      driver.find_element(:css, '.upload_new_file_link').click
      driver.find_element(:id, 'attachment_uploaded_data').send_keys(fullpath)
      driver.find_element(:css, '#sidebar_upload_file_form button').click
      wait_for_ajax_requests
      keep_trying_until { driver.execute_script("return $('#tree1 .leaf:contains(#{filename})').length") > 0 }

      # let's go check out if the file is in the files controller
      get "/courses/#{@course.id}/files"
      keep_trying_until { driver.execute_script("return $('a:contains(#{filename})')[0]") }

      # check out the file content, make sure it's good
      get "/courses/#{@course.id}/files/#{Attachment.last.id}/download?wrap=1"
      in_frame('file_content') do
        driver.page_source.should match data
      end
    end
  end
end

describe "file uploads S3 tests" do
  it_should_behave_like "file uploads selenium tests"
  prepend_before (:each) do
    Setting.set("file_storage_test_override", "s3")
  end
  prepend_before (:all) do
    Setting.set("file_storage_test_override", "s3")
  end
end
