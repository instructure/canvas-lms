require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations" do
  include_examples "in-process server selenium tests"

  before (:each) do
    conversation_setup
  end

  it "should not allow double form submissions" do
    new_message = 'new conversation message'
    @s1 = User.create(:name => 'student1')
    @course.enroll_user(@s1)
    new_conversation
    add_recipient("student1")

    expect {
      f('#create_message_form .conversation_body').send_keys(new_message)
      5.times { submit_form('#create_message_form form') rescue nil }
      assert_message_status("sent", new_message[0, 10])
    }.to change(ConversationMessage, :count).by(1)
  end

  describe 'actions' do
    def create_conversation(workflow_state = 'unread', starred = false, url = '/conversations')
      @me = @user
      conversation(@me, user, :workflow_state => workflow_state, :starred => starred)
      get url unless url == nil
    end

    it "should auto-mark as read" do
      @me = @user
      5.times { conversation(@me, user, :workflow_state => 'unread') }
      get "/conversations/unread"
      ce = get_conversations.first
      ce.should have_class('unread') # not marked immediately
      ce.click
      wait_for_ajaximations
      @me.conversations.unread.size.should == 5
      keep_trying_until do
        get_conversations.first.should_not have_class('unread')
        true
      end
      @me.conversations.unread.size.should == 4

      get_conversations.last.click
      get_conversations.size.should == 4 # removed once deselected
    end

    it "should not open the conversation when the gear menu is clicked" do
      create_conversation
      wait_for_ajaximations
      f('#menu-wrapper .al-options').should be_nil
      driver.execute_script "$('.admin-link-hover-area').addClass('active')"
      f('.admin-links button').click
      wait_for_ajaximations
      f('#menu-wrapper .al-options').should be_displayed
      f('.messages').should_not be_displayed
    end

    it "should star a conversation" do
      create_conversation

      f('#conversations .action_star').click
      wait_for_ajaximations
      f('#conversations .action_unstar').should be_displayed
      f('#conversations .action_star').should_not be_displayed
    end

    it "should unstar a conversation" do
      create_conversation('unread', true)

      f('#conversations .action_unstar').click
      wait_for_ajaximations
      f('#conversations .action_star').should be_displayed
      f('#conversations .action_unstar').should_not be_displayed
    end

    it "should mark a conversation as unread" do
      create_conversation('read', false)

      f('.action_mark_as_unread').click
      wait_for_ajaximations
      f('.action_mark_as_unread').should_not be_displayed
      f('.action_mark_as_read').should be_displayed
      expect_new_page_load { get '/conversations/archived' }
      f('.conversations .audience').should include_text('New Message')
    end

    it "should delete a conversation" do
      create_conversation
      wait_for_ajaximations
      driver.execute_script "$('.admin-link-hover-area').addClass('active')"

      f('.admin-links button').click
      f('.al-options .action_delete_all').click
      driver.switch_to.alert.accept
      wait_for_ajaximations

      f('#no_messages').should be_displayed
    end

    it "should archive a conversation" do
      create_conversation

      wait_for_ajaximations
      driver.execute_script("$('.admin-link-hover-area').addClass('active')")
      f('.admin-links button').click
      f('.al-options .action_archive').click
      wait_for_ajaximations
      f('#no_messages').should be_displayed
      expect_new_page_load { get '/conversations/archived' }
      f('.conversations .audience').should include_text('User')
    end

    it "should allow you to filter a conversation by sent" do
      create_conversation

      expect_new_page_load { get '/conversations/archived' }
      f('.conversations .audience').should include_text('New Message')
    end
  end

  context "New message... link" do
    before :each do
      @me = @user
      @other = user(:name => 'Some OtherDude')
      @course.enroll_student(@other)
      conversation(@me, @other, :workflow_state => 'unread')
      @participant_me = @conversation
      @convo = @participant_me.conversation
      @convo.add_message(@other, "Hey bud!")
      @convo.add_message(@me, "Howdy friend!")
      get '/conversations'
      f('.unread').click
      wait_for_ajaximations
    end

    it "should not display on my own message" do
      # Hover over own message
      driver.execute_script("$('.message.self:first .send_private_message').focus()")
      f(".message.self .send_private_message").should_not be_displayed
    end

    it "should display on messages from others" do
      # Hover over the message from the other writer to display link
      # This spec fails locally in isolation and in this context block.
      driver.execute_script("$('.message.other .send_private_message').focus()")
      f(".message.other .send_private_message").should be_displayed
    end

    it "should start new message to the user" do
      f(".message.other .send_private_message").click()
      wait_for_ajaximations
      # token gets added after brief delay
      sleep(0.4)
      # create "token" with the 'other' user
      f("#create_message_form .token_input ul").text().should == @other.name
    end
  end

  context 'messages' do
    before(:each) do
      @me = @user
      conversation(@me, user, :workflow_state => 'unread')
      get '/conversations'
      f('.unread').click
      wait_for_ajaximations
      f(".messages #message_#{ConversationMessage.last.id}").click
    end

    it "should forward a message" do
      forward_body_text = 'new forward'
      f('#action_forward').click
      fj('#forward_message_form .token_input input').send_keys('nobody')
      wait_for_ajaximations
      f('.selectable').click
      f('#forward_body').send_keys(forward_body_text)
      f('.ui-dialog-buttonset > .btn-primary').click
      wait_for_ajaximations
      expect_new_page_load { get '/conversations/sent' }
      f('.conversations li.read').should include_text(forward_body_text)
    end

    it "should delete a message" do
      f('#action_delete').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      f('#no_messages').should be_displayed
    end
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
        keep_trying_until do
          get_conversations.first.should_not have_class('unread')
          true
        end
        get '/conversations'
        f('.unread-messages-count').text.should == '4'
      end
    end
  end

  context "media comments" do
    it "should add audio and video comments to the message form" do
      # don't have a good way to test kaltura here, so we just fake it up
      CanvasKaltura::ClientV3.expects(:config).at_least(1).returns({})

      ['audio', 'video'].each_with_index do |media_comment_type, index|
        mo = MediaObject.new
        mo.media_id = "0_12345678#{index}"
        mo.media_type = media_comment_type
        mo.context = @user
        mo.user = @user
        mo.title = "test title"
        mo.save!

        new_conversation(:message => media_comment_type)

        message = submit_message_form(:media_comment => [mo.media_id, mo.media_type])

        expect_new_page_load { get '/conversations/sent' }
        f('.conversations li').click
        wait_for_ajaximations
        message = "#message_#{message.id}"
        ff("#{message} .message_attachments li").size.should == 1
        f("#{message} .message_attachments li a .title").text.should == mo.title
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

      ffj("#conversations .audience a").should be_empty
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

      submit_message_form(:message => "ohai", :add_recipient => false, :existing_conversation => true).should_not be_nil
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
      f("#create_message_form .conversation_body").send_keys "testing testing"
      submit_form('#create_message_form')

      wait_for_ajaximations

      assert_message_status "sending"
      run_jobs
      assert_message_status "sent"

      # no conversations should show up in the conversation list
      get_conversations(false).should be_empty
    end
  end

  context "bulk popovers" do
    before (:each) do
      @number_of_people = 10
      @conversation_students = []
      @number_of_people.times do |i|
        u = User.create!(:name => "conversation student #{i}")
        @course.enroll_user(u, "StudentEnrollment").accept!
        @conversation_students << u
      end
    end

    it "should validate the others popover" do
      new_conversation
      @conversation_students.each { |student| add_recipient(student.name) }
      f("#create_message_form .conversation_body").send_keys "testing testing"
      f('.group_conversation').click
      submit_form('#create_message_form')
      wait_for_ajaximations
      run_jobs
      expect_new_page_load { get "/conversations/sent" }
      wait_for_ajaximations
      f('.others').click
      f('#others_popup').should be_displayed
      ff('#others_popup li').count.should == (@conversation_students.count - 2) # - 2 because the first 2 show up in the conversation summary
    end
  end

  context "help menu" do
    it "should switch to new conversations and redirect" do
      site_admin_logged_in
      @user.watched_conversations_intro
      @user.save
      new_conversation
      f('#help-btn').click
      expect_new_page_load { fj('#try-new-conversations-menu-item').click }
      f('#inbox').should be_nil # #inbox is in the old conversations ui and not the new ui
      driver.execute_script("$('#help-btn').click()") #selenium.clik() not working in this case...
      expect_new_page_load {  fj('#switch-to-old-conversations-menu-item').click }
      f('#inbox').should be_displayed
    end

    it "should show the intro" do
      site_admin_logged_in
      @user.watched_conversations_intro
      @user.save
      new_conversation
      f('#help-btn').click
      fj('#conversations-intro-menu-item').click
      wait_for_ajaximations
      ff('#conversations_intro').last.should be_displayed
    end
  end
end
