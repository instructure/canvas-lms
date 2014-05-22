require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations new" do
  include_examples "in-process server selenium tests"

  def conversations_url
    "/conversations"
  end

  def get_conversations
    get conversations_url
    wait_for_ajaximations
  end

  def conversation_elements
    ff('.messages > li')
  end

  def get_view_filter
    f('.type-filter.bootstrap-select')
  end

  def get_course_filter
    pending('course filter selector fails intermittently (stale element reference), probably due to dynamic loading and refreshing')
    #try to make it load the courses first so it doesn't randomly refresh
    selector = '.course-filter.bootstrap-select'
    driver.execute_script(%{$('#{selector}').focus();})
    wait_for_ajaximations
    f(selector)
  end

  def get_message_course
    fj('.message_course.bootstrap-select')
  end

  def get_message_recipients_input
    fj('.compose_form #compose-message-recipients')
  end

  def get_message_subject_input
    fj('#compose-message-subject')
  end

  def get_message_body_input
    fj('.conversation_body')
  end

  def get_bootstrap_select_value(element)
    f('.selected .text', element).attribute('data-value')
  end

  def set_bootstrap_select_value(element, new_value)
    f('.dropdown-toggle', element).click()
    f(%{.text[data-value="#{new_value}"]}, element).click()
  end

  def select_view(new_view)
    set_bootstrap_select_value(get_view_filter, new_view)
    wait_for_ajaximations
  end

  def select_course(new_course)
    set_bootstrap_select_value(get_course_filter, new_course)
    wait_for_ajaximations
  end

  def click_star_toggle_menu_item
    keep_trying_until do
      driver.execute_script(%q{$('#admin-btn').hover().click()})
      sleep 1
      driver.execute_script(%q{$('#star-toggle-btn').hover().click()})
      wait_for_ajaximations
    end
  end

  def click_unread_toggle_menu_item
    keep_trying_until do
      driver.execute_script(%q{$('#admin-btn').hover().click()})
      sleep 1
      driver.execute_script(%q{$('#mark-unread-btn').hover().click()})
      wait_for_ajaximations
    end
  end

  def click_read_toggle_menu_item
    keep_trying_until do
      driver.execute_script(%q{$('#admin-btn').hover().click()})
      sleep 1
      driver.execute_script(%q{$('#mark-read-btn').hover().click()})
      wait_for_ajaximations
    end
  end

  def select_message_course(new_course, is_group = false)
    new_course = new_course.name if new_course.respond_to? :name
    fj('.dropdown-toggle', get_message_course).click
    if is_group
      wait_for_ajaximations
      fj("a:contains('Groups')", get_message_course).click
    end
    fj("a:contains('#{new_course}')", get_message_course).click
  end

  def add_message_recipient(to)
    synthetic = !(to.instance_of?(User) || to.instance_of?(String))
    to = to.name if to.respond_to?(:name)
    get_message_recipients_input.send_keys(to)
    keep_trying_until { fj(".ac-result:contains('#{to}')") }.click
    return unless synthetic
    keep_trying_until { fj(".ac-result:contains('All in #{to}')") }.click
  end

  def set_message_subject(subject)
    get_message_subject_input.send_keys(subject)
  end

  def set_message_body(body)
    get_message_body_input.send_keys(body)
  end

  def click_send
    f('.send-message').click
    wait_for_ajaximations
  end

  def compose(options={})
    fj('#compose-btn').click
    wait_for_ajaximations
    select_message_course(options[:course]) if options[:course]
    (options[:to] || []).each {|recipient| add_message_recipient recipient}
    set_message_subject(options[:subject]) if options[:subject]
    set_message_body(options[:body]) if options[:body]
    click_send if options[:send].nil? || options[:send]
  end

  def run_progress_job
    return unless progress = Progress.where(tag: 'conversation_batch_update').first
    job = Delayed::Job.find(progress.delayed_job_id)
    job.invoke_job
  end

  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
  end

  describe "message sending" do
    it "should start a group conversation when there is only one recipient" do
      get_conversations
      compose course: @course, to: [@s1], subject: 'single recipient', body: 'hallo!'
      c = @s1.conversations.last.conversation
      c.subject.should ==('single recipient')
      c.private?.should be_false
    end

    it "should start a group conversation when there is more than one recipient" do
      get_conversations
      compose course: @course, to: [@s1, @s2], subject: 'multiple recipients', body: 'hallo!'
      c = @s1.conversations.last.conversation
      c.subject.should ==('multiple recipients')
      c.private?.should be_false
      c.conversation_participants.collect(&:user_id).sort.should ==([@teacher, @s1, @s2].collect(&:id).sort)
    end

    it "should allow admins to send a message without picking a context" do
      user = account_admin_user
      user_logged_in({:user => user})
      get_conversations
      compose to: [@s1], subject: 'context-free', body: 'hallo!'
      c = @s1.conversations.last.conversation
      c.subject.should == 'context-free'
      c.context.should == Account.default
    end

    it "should not allow non-admins to send a message without picking a context" do
      get_conversations
      fj('#compose-btn').click
      wait_for_animations
      fj('#compose-new-message .ac-input').should have_attribute(:disabled, 'true')
    end

    it "should allow non-admins to send a message to an account-level group" do
      @group = Account.default.groups.create(:name => "the group")
      @group.add_user(@s1)
      @group.add_user(@s2)
      @group.save
      user_logged_in({:user => @s1})
      get_conversations
      fj('#compose-btn').click
      wait_for_ajaximations
      select_message_course(@group, true)
      add_message_recipient @s2
    end

    it "should allow admins to message users from their profiles" do
      user = account_admin_user
      user_logged_in({:user => user})
      get "/accounts/#{Account.default.id}/users"
      wait_for_ajaximations
      f('li.user a').click
      wait_for_ajaximations
      f('.icon-email').click
      wait_for_ajaximations
      f('.ac-token').should_not be_nil
    end

    context "user notes" do
      before(:each) do
        @course.account.update_attribute(:enable_user_notes, true)
        user_session(@teacher)
        get_conversations
      end

      it "should be allowed on new private conversations with students" do
        compose course: @course, to: [@s1], body: 'hallo!', send: false

        checkbox = f(".user_note")
        checkbox.should be_displayed
        checkbox.click

        count = @s1.user_notes.count
        click_send
        @s1.user_notes.reload.count.should == count + 1
      end

      it "should not be allowed if disabled" do
        @course.account.update_attribute(:enable_user_notes, false)
        get_conversations
        compose course: @course, to: [@s1], body: 'hallo!', send: false
        f(".user_note").should_not be_displayed
      end

      it "should not be allowed for students" do
        user_session(@s1)
        get_conversations
        compose course: @course, to: [@s2], body: 'hallo!', send: false
        f(".user_note").should_not be_displayed
      end

      it "should not be allowed with multiple recipients" do
        compose course: @course, to: [@s1, @s2], body: 'hallo!', send: false
        f(".user_note").should_not be_displayed
      end

      it "should not be allowed with non-student recipient" do
        compose course: @course, to: [@teacher], body: 'hallo!', send: false
        f(".user_note").should_not be_displayed
      end

      it "should not be allowed with group recipient" do
        @group = @course.groups.create(:name => "the group")
        compose course: @course, to: [@group], body: 'hallo!', send: false
        f(".user_note").should_not be_displayed
      end
    end
  end

  describe "replying" do
    before do
      cp = conversation(@s1, @teacher, @s2, workflow_state: 'unread')
      @convo = cp.conversation
      @convo.update_attribute(:subject, 'homework')
      @convo.add_message(@s1, "What's this week's homework?")
      @convo.add_message(@s2, "I need the homework too.")
    end

    it "should maintain context and subject" do
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      fj('#compose-message-course').should have_attribute(:disabled, 'true')
      fj('#compose-message-course').should have_value(@course.id.to_s)
      fj('#compose-message-subject').should have_attribute(:disabled, 'true')
      fj('#compose-message-subject').should_not be_displayed
      fj('#compose-message-subject').should have_value(@convo.subject)
      fj('.message_subject_ro').should be_displayed
      fj('.message_subject_ro').text.should == @convo.subject
    end

    it "should address replies to the most recent author by default" do
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      ffj('input[name="recipients[]"]').length.should == 1
      fj('input[name="recipients[]"]').should have_value(@s2.id.to_s)
    end

    it "should add new messages to the conversation" do
      get_conversations
      initial_message_count = @convo.conversation_messages.length
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      set_message_body('Read chapters five and six.')
      click_send
      wait_for_ajaximations
      ffj('.message-item-view').length.should == initial_message_count + 1
      @convo.reload
      @convo.conversation_messages.length.should == initial_message_count + 1
    end

    it "should not allow adding recipients to private messages" do
      @convo.update_attribute(:private_hash, '12345')
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      fj('.compose_form .ac-input-box.disabled').should_not be_nil
    end
  end

  describe "view filter" do
    before do
      conversation(@teacher, @s1, @s2, workflow_state: 'unread')
      conversation(@teacher, @s1, @s2, workflow_state: 'read', starred: true)
      conversation(@teacher, @s1, @s2, workflow_state: 'archived', starred: true)
    end

    it "should default to inbox view" do
      get_conversations
      selected = get_bootstrap_select_value(get_view_filter).should == 'inbox'
      conversation_elements.size.should == 2
    end

    it "should have an unread view" do
      get_conversations
      select_view('unread')
      conversation_elements.size.should == 1
    end

    it "should have an starred view" do
      get_conversations
      select_view('starred')
      conversation_elements.size.should == 2
    end

    it "should have an sent view" do
      get_conversations
      select_view('sent')
      conversation_elements.size.should == 3
    end

    it "should have an archived view" do
      get_conversations
      select_view('archived')
      conversation_elements.size.should == 1
    end

    it "should default to all courses view" do
      get_conversations
      selected = get_bootstrap_select_value(get_course_filter).should == ''
      conversation_elements.size.should == 2
    end

    it "should truncate long course names" do
      @course.name = "this is a very long course name that will be truncated"
      @course.save!
      get_conversations
      select_course(@course.id)
      button_text = f('.filter-option', get_course_filter).text
      button_text.should_not == @course.name
      button_text[0...5].should == @course.name[0...5]
      button_text[-5..-1].should == @course.name[-5..-1]
    end

    it "should filter by course" do
      get_conversations
      select_course(@course.id)
      conversation_elements.size.should == 2
    end

    it "should filter by course plus view" do
      get_conversations
      select_course(@course.id)
      select_view('unread')
      conversation_elements.size.should == 1
    end

    it "should hide the spinner after deleting the last conversation" do
      get_conversations
      select_view('archived')
      conversation_elements.size.should == 1
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      conversation_elements.size.should == 0
      ffj('.message-list .paginatedLoadingIndicator:visible').length.should == 0
    end
  end

  describe "starred" do
    before do
      @conv_unstarred = conversation(@teacher, @s1, @s2)
      @conv_starred = conversation(@teacher, @s1, @s2)
      @conv_starred.starred = true
      @conv_starred.save!
    end

    it "should star via star icon" do
      get_conversations
      unstarred_elt = conversation_elements[1]
      # make star button visible via mouse over
      driver.mouse.move_to(unstarred_elt)
      wait_for_ajaximations
      star_btn = f('.star-btn', unstarred_elt)
      star_btn.should be_present
      f('.active', unstarred_elt).should be_nil

      star_btn.click
      wait_for_ajaximations
      f('.active', unstarred_elt).should be_present
      @conv_unstarred.reload.starred.should be_true
    end

    it "should unstar via star icon" do
      get_conversations
      starred_elt = conversation_elements[0]
      star_btn = f('.star-btn', starred_elt)
      star_btn.should be_present
      f('.active', starred_elt).should be_present

      star_btn.click
      wait_for_ajaximations
      f('.active', starred_elt).should be_nil
      @conv_starred.reload.starred.should be_false
    end

    it "should star via gear menu" do
      get_conversations
      unstarred_elt = conversation_elements[1]
      unstarred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      f('.active', unstarred_elt).should be_present
      run_progress_job
      @conv_unstarred.reload.starred.should be_true
    end

    it "should unstar via gear menu" do
      get_conversations
      starred_elt = conversation_elements[0]
      starred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      f('.active', starred_elt).should be_nil
      run_progress_job
      @conv_starred.reload.starred.should be_false
    end
  end

  describe "search" do
    before do
      @conv1 = conversation(@teacher, @s1)
      @conv2 = conversation(@teacher, @s2)
    end

    it "should allow finding messages by recipient" do
      get_conversations
      name = @s2.name
      f('[role=main] header [role=search] input').send_keys(name)
      keep_trying_until { fj(".ac-result:contains('#{name}')") }.click
      conversation_elements.length.should == 1
    end
  end

  describe "multi-select" do
    before(:each) do
      @conversations = [conversation(@teacher, @s1, @s2, workflow_state: 'read'),
                        conversation(@teacher, @s1, @s2, workflow_state: 'read')]
    end

    let :modifier do
      if driver.execute_script('return !!window.navigator.userAgent.match(/Macintosh/)')
        :meta
      else
        :control
      end
    end

    def select_all_conversations
      driver.action.key_down(modifier).perform
      ff('.messages li').each do |message|
        message.click
      end
      driver.action.key_up(modifier).perform
    end

    it "should select multiple conversations" do
      get_conversations
      select_all_conversations
      ff('.messages li.active').count.should == 2
    end

    it "should select all conversations" do
      get_conversations
      driver.action.key_down(modifier)
        .send_keys('a')
        .key_up(modifier)
        .perform
      ff('.messages li.active').count.should == 2
    end

    it "should archive multiple conversations" do
      get_conversations
      select_all_conversations
      f('#archive-btn').click
      wait_for_ajaximations
      conversation_elements.count.should == 0
      run_progress_job
      @conversations.each { |c| c.reload.should be_archived }
    end

    it "should delete multiple conversations" do
      get_conversations
      select_all_conversations
      f('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      conversation_elements.count.should == 0
    end

    it "should mark multiple conversations as unread" do
      pending('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_unread_toggle_menu_item
      keep_trying_until { ffj('.read-state[aria-checked=false]').count.should == 2 }
    end

    it "should mark multiple conversations as unread" do
      pending('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_read_toggle_menu_item
      keep_trying_until { ffj('.read-state[aria-checked=true]').count.should == 2 }
    end

    it "should star multiple conversations" do
      pending('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_star_toggle_menu_item
      run_progress_job
      keep_trying_until { ff('.star-btn.active').count.should == 2 }
      @conversations.each { |c| c.reload.should be_starred }
    end
  end
end
