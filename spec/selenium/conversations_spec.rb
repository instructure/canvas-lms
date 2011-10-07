require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "conversations selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @user.watched_conversations_intro
    @user.save
  end

  def new_conversation
    get "/conversations"
    keep_trying_until{ driver.find_element(:id, "create_message_form") }
  end

  def submit_message_form(opts={})
    opts[:message] ||= "Test Message"
    opts[:attachments] ||= []
    opts[:add_recipient] = true unless opts.has_key?(:add_recipient)

    if opts[:add_recipient] && browser = find_with_jquery("#create_message_form .browser:visible")
      browser.click
      keep_trying_until{
        if elem = find_with_jquery('.selectable:visible')
          elem.click
        end
        elem
      }
    end

    find_with_jquery("#create_message_form textarea").send_keys(opts[:message])

    opts[:attachments].each_with_index do |fullpath, i|
      driver.find_element(:id, "action_add_attachment").click
      
      keep_trying_until {
        find_all_with_jquery("#create_message_form .file_input:visible")[i]
      }.send_keys(fullpath)
    end

    if opts[:media_comment]
      driver.execute_script <<-JS
        $("#media_comment_id").val(#{opts[:media_comment].first.inspect})
        $("#media_comment_type").val(#{opts[:media_comment].last.inspect})
        $("#create_message_form .media_comment").show()
        $("#action_media_comment").hide()
      JS
    end

    expect {
      find_with_jquery("#create_message_form button[type='submit']").click
      wait_for_ajax_requests
    }.to change(ConversationMessage, :count).by(1)

    message = ConversationMessage.last
    driver.find_element(:id, "message_#{message.id}").should_not be_nil
    message
  end

  context "conversation loading" do
    it "should load all conversations" do
      @me = @user
      num = 51
      num.times { conversation(@me, user) }
      get "/conversations"
      keep_trying_until{
        elements = find_all_with_jquery("#conversations > ul > li:visible")
        elements.last.location_once_scrolled_into_view
        elements.size == num
      }
    end
  end

  context "media comments" do
    it "should add a media comment to the message form" do
      # don't have a good way to test kaltura here, so we just fake it up
      Kaltura::ClientV3.should_receive(:config).at_least(:once).and_return({})
      mo = MediaObject.new
      mo.media_id = '0_12345678'
      mo.media_type = 'audio'
      mo.context = @user
      mo.user = @user
      mo.title = "test title"
      mo.save!

      new_conversation

      message = submit_message_form(:media_comment => [mo.media_id, mo.media_type])
      message = "#message_#{message.id}"

      find_all_with_jquery("#{message} .message_attachments li").size.should == 1
      find_with_jquery("#{message} .message_attachments li a .title").text.should == mo.title
    end
  end

  context "attachments" do
    it "should be able to add an attachment to the message form" do
      new_conversation

      add_attachment_link = driver.find_element(:id, "action_add_attachment")
      add_attachment_link.should_not be_nil
      find_all_with_jquery("#attachment_list > .attachment:visible").should be_empty
      add_attachment_link.click
      keep_trying_until{ find_all_with_jquery("#attachment_list > .attachment:visible").should be_present }
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
      find_with_jquery("#{message} .message_attachments li a").click
      driver.page_source.should match data
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

  context "user notes" do
    before do
      @the_teacher = User.create(:name => "teacher bob")
      @course.enroll_teacher(@the_teacher)
      @the_student = User.create(:name => "student bob")
      @course.enroll_student(@the_student)
    end

    def add_recipient(search)
      input = find_with_jquery("#create_message_form input:visible")
      input.send_keys(search)
      keep_trying_until{ driver.execute_script("return $('#recipients').data('token_input').selector.last_search") == search }
      input.send_keys(:return)
    end

    it "should not allow user notes if not enabled" do
      @course.account.update_attribute :enable_user_notes, false
      new_conversation
      add_recipient("student bob")
      driver.find_element(:id, "add_to_faculty_journal").should_not be_displayed
    end

    it "should not allow user notes to teachers" do
      @course.account.update_attribute :enable_user_notes, true
      new_conversation
      add_recipient("teacher bob")
      driver.find_element(:id, "add_to_faculty_journal").should_not be_displayed
    end

    it "should not allow user notes on group conversations" do
      @course.account.update_attribute :enable_user_notes, true
      new_conversation
      add_recipient("student bob")
      add_recipient("teacher bob")
      driver.find_element(:id, "add_to_faculty_journal").should_not be_displayed
      find_with_jquery("#create_message_form input:visible").send_keys :backspace
      driver.find_element(:id, "add_to_faculty_journal").should be_displayed
    end

    it "should allow user notes on new private conversations with students" do
      @course.account.update_attribute :enable_user_notes, true
      new_conversation
      add_recipient("student bob")
      checkbox = driver.find_element(:id, "add_to_faculty_journal")
      checkbox.should be_displayed
      checkbox.click
      submit_message_form(:add_recipient => false)
      @the_student.user_notes.size.should eql(1)
    end

    it "should allow user notes on existing private conversations with students" do
      @course.account.update_attribute :enable_user_notes, true
      new_conversation
      add_recipient("student bob")
      submit_message_form(:add_recipient => false)
      checkbox = driver.find_element(:id, "add_to_faculty_journal")
      checkbox.should be_displayed
      checkbox.click
      submit_message_form
      @the_student.user_notes.size.should eql(1)
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
