require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "conversations selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  context "attachments" do
    def new_conversation
      get "/conversations"
      keep_trying_until{ driver.find_element(:id, "create_message_form") }
    end

    def submit_message_form(opts={})
      opts[:message] ||= "Test Message"
      opts[:attachments] ||= []

      if browser = find_with_jquery("#create_message_form .browser:visible")
        browser.click
        keep_trying_until{ find_with_jquery('.selectable:visible').click }
      end

      find_with_jquery("#create_message_form textarea").send_keys(opts[:message])

      opts[:attachments].each do |fullpath|
        driver.find_element(:id, "action_add_attachment").click
        find_all_with_jquery("#create_message_form .file_input:visible").last.send_keys(fullpath)
      end

      old_count = ConversationMessage.count
      find_with_jquery("#create_message_form button[type='submit']").click
      wait_for_ajax_requests

      ConversationMessage.count.should == old_count + 1
      message = ConversationMessage.last
      driver.find_element(:id, "message_#{message.id}").should_not be_nil
      message
    end

    it "should be able to add an attachment to the message form" do
      course_with_teacher_logged_in
      new_conversation

      add_attachment_link = driver.find_element(:id, "action_add_attachment")
      add_attachment_link.should_not be_nil
      find_all_with_jquery("#attachment_list > .attachment:visible").should be_empty
      add_attachment_link.click
      find_all_with_jquery("#attachment_list > .attachment:visible").should_not be_empty
    end

    it "should be able to add multiple attachments to the message form" do
      course_with_teacher_logged_in
      new_conversation

      add_attachment_link = driver.find_element(:id, "action_add_attachment")
      add_attachment_link.click
      add_attachment_link.click
      add_attachment_link.click
      find_all_with_jquery("#attachment_list > .attachment:visible").size.should == 3
    end

    it "should be able to remove attachments from the message form" do
      course_with_teacher_logged_in
      new_conversation

      add_attachment_link = driver.find_element(:id, "action_add_attachment")
      add_attachment_link.click
      add_attachment_link.click
      find_with_jquery("#attachment_list > .attachment:visible .remove_link").click
      keep_trying_until{ find_all_with_jquery("#attachment_list > .attachment:visible").size.should == 1 }
    end

    it "should save attachments on initial messages on new conversations" do
      course_with_teacher_logged_in
      student_in_course
      filename, fullpath, data = get_file("testfile1.txt")

      new_conversation
      message = submit_message_form(:attachments => [fullpath])
      message = "#message_#{message.id}"

      find_all_with_jquery("#{message} .message_attachments li").size.should == 1
      find_with_jquery("#{message} .message_attachments li a .title").text.should == filename
      find_with_jquery("#{message} .message_attachments li a").click
      driver.page_source.should match data
    end

    it "should save attachments on new messages on existing conversations" do
      course_with_teacher_logged_in
      student_in_course
      filename, fullpath, data = get_file("testfile1.txt")

      new_conversation
      submit_message_form

      message = submit_message_form(:attachments => [fullpath])
      message = "#message_#{message.id}"

      find_all_with_jquery("#{message} .message_attachments li").size.should == 1
    end

    it "should save multiple attachments" do
      course_with_teacher_logged_in
      student_in_course
      file1 = get_file("testfile1.txt")
      file2 = get_file("testfile2.txt")

      new_conversation
      message = submit_message_form(:attachments => [file1[1], file2[1]])
      message = "#message_#{message.id}"

      find_all_with_jquery("#{message} .message_attachments li").size.should == 2
      find_with_jquery("#{message} .message_attachments li:first a .title").text.should == file1[0]
      find_with_jquery("#{message} .message_attachments li:last a .title").text.should == file2[0]
    end
  end
end

describe "conversations Windows-Firefox-Tests" do
  it_should_behave_like "conversations selenium tests"
  prepend_before(:each) {
    Setting.set("file_storage_test_override", "local")
  }
  prepend_before(:all) {
    Setting.set("file_storage_test_override", "local")
  }
end
