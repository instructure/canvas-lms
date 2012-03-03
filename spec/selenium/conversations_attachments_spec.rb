require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/conversations_common')

describe "conversations attachments" do
  it_should_behave_like "conversations selenium tests"

  it "should be able to add an attachment to the message form" do
    new_conversation

    add_attachment_link = driver.find_element(:id, "action_add_attachment")
    add_attachment_link.should_not be_nil
    find_all_with_jquery("#attachment_list > .attachment:visible").should be_empty
    add_attachment_link.click
    keep_trying_until { find_all_with_jquery("#attachment_list > .attachment:visible").should be_present }
  end

  it "should be able to add multiple attachments to the message form" do
    new_conversation

    add_attachment_link = driver.find_element(:id, "action_add_attachment")
    add_attachment_link.click
    wait_for_animations
    add_attachment_link.click
    wait_for_animations
    add_attachment_link.click
    wait_for_animations
    find_all_with_jquery("#attachment_list > .attachment:visible").size.should == 3
  end

  it "should be able to remove attachments from the message form" do
    new_conversation

    add_attachment_link = driver.find_element(:id, "action_add_attachment")
    add_attachment_link.click
    wait_for_animations
    add_attachment_link.click
    wait_for_animations
    find_all_with_jquery("#attachment_list > .attachment:visible .remove_link")[1].click
    wait_for_animations
    find_all_with_jquery("#attachment_list > .attachment:visible").size.should == 1
  end

  it "should save attachments on initial messages on new conversations" do
    student_in_course
    filename, fullpath, data = get_file("testfile1.txt")

    new_conversation
    message = submit_message_form(:attachments => [fullpath])
    message = "#message_#{message.id}"

    find_all_with_jquery("#{message} .message_attachments li").size.should == 1
    find_with_jquery("#{message} .message_attachments li a .title").text.should == filename
    download_link = driver.find_element(:css, "#{message} .message_attachments li a")
    file = open(download_link.attribute('href'))
    file.read.should match data
  end

  it "should save attachments on new messages on existing conversations" do
    student_in_course
    filename, fullpath, data = get_file("testfile1.txt")

    new_conversation
    submit_message_form

    message = submit_message_form(:attachments => [fullpath])
    message = "#message_#{message.id}"

    find_all_with_jquery("#{message} .message_attachments li").size.should == 1
  end

  it "should save multiple attachments" do
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
