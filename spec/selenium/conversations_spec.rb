require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations" do
  it_should_behave_like "in-process server selenium tests"
  it_should_behave_like "conversations selenium tests"

  it "should not allow double form submissions" do
    new_message = 'new conversation message'
    @s1 = User.create(:name => 'student1')
    @course.enroll_user(@s1)
    new_conversation
    add_recipient("student1")

    expect {
      f('#body').send_keys(new_message)
      5.times { submit_form('#create_message_form') }
      keep_trying_until{ get_conversations.size == 1 }
    }.to change(ConversationMessage, :count).by(1)
  end

  it "should auto-mark as read" do
    @me = @user
    5.times { conversation(@me, user, :workflow_state => 'unread') }
    get "/conversations/unread"
    c = get_conversations.first
    c.click
    c[:class].should =~ /unread/ # not marked immediately
    @me.conversations.unread.size.should eql 5
    keep_trying_until { get_conversations.first[:class] !~ /unread/ }
    @me.conversations.unread.size.should eql 4

    get_conversations.last.click
    get_conversations.size.should eql 4 # removed once deselected
  end

  context "conversation loading" do
    it "should load all conversations" do
      @me = @user
      num = 51
      num.times { conversation(@me, user) }
      get "/conversations"
      keep_trying_until do
        elements = get_conversations
        elements.last.location_once_scrolled_into_view
        elements.size.should == num
      end
    end

    it "should properly clear the identity header when conversations are read" do
      enable_cache do
        @me = @user
        5.times { conversation(@me, user, :workflow_state => 'unread') }
        get_messages # loads the page, clicks the first conversation
        keep_trying_until { get_conversations.first[:class] !~ /unread/ }
        get '/conversations'
        driver.find_element(:css, '.unread-messages-count').text.should eql '4'
      end
    end
  end

  context "media comments" do
    it "should add audio and video comments to the message form" do
      # don't have a good way to test kaltura here, so we just fake it up
      Kaltura::ClientV3.expects(:config).at_least(1).returns({})

      ['audio', 'video'].each_with_index do |media_comment_type, index|
        mo = MediaObject.new
        mo.media_id = "0_12345678#{index}"
        mo.media_type = media_comment_type
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
  end

  context "form audience" do
    before (:each) do
      # have @course, @teacher from before
      # creates @student
      student_in_course(:course => @course, :active_all => true)

      @course.update_attribute(:name, "the course")

      @group = @course.groups.create(:name => "the group")
      @group.participating_users << @student

      conversation(@teacher, @student)
    end

    it "should link to the course page" do
      get_messages

      expect_new_page_load { fj("#create_message_form .audience a").click }
      driver.current_url.should match %r{/courses/#{@course.id}}
    end

    it "should not be a link in the left conversation list panel" do
      new_conversation

      find_all_with_jquery("#conversations .audience a").should be_empty
    end
  end

  context "private messages" do
    before do
      @course.update_attribute(:name, "the course")
      @course1 = @course
      @s1 = User.create(:name => "student1")
      @s2 = User.create(:name => "student2")
      @course1.enroll_user(@s1)
      @course1.enroll_user(@s2)

      ConversationMessage.any_instance.stubs(:current_time_from_proper_timezone).returns(*100.times.to_a.reverse.map { |h| Time.now.utc - h.hours })

      @c1 = conversation(@user, @s1)
      @c1.add_message('yay i sent this')
    end

    it "should select the new conversation" do
      new_conversation
      add_recipient("student2")

      submit_message_form(:message => "ohai", :add_recipient => false).should_not be_nil
    end

    it "should select the existing conversation" do
      new_conversation
      add_recipient("student1")

      submit_message_form(:message => "ohai", :add_recipient => false).should_not be_nil
    end
  end

  context "batch messages" do
    it "shouldn't show anything in conversation list when sending batch messages to new recipients" do
      @course.default_section.update_attribute(:name, "the section")

      @s1 = User.create(:name => "student1")
      @s2 = User.create(:name => "student2")
      @course.enroll_user(@s1)
      @course.enroll_user(@s2)

      new_conversation

      add_recipient("student1")
      add_recipient("student2")
      driver.find_element(:id, "body").send_keys "testing testing"
      submit_form('#create_message_form')

      wait_for_ajaximations

      assert_flash_notice_message /Messages Sent/

      # no conversations should show up in the conversation list
      get_conversations(false).should be_empty
    end
  end
end
