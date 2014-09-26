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
    skip('course filter selector fails intermittently (stale element reference), probably due to dynamic loading and refreshing')
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
    f('.compose-message-dialog .send-message').click
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

  let :modifier do
    if driver.execute_script('return !!window.navigator.userAgent.match(/Macintosh/)')
      :meta
    else
      :control
    end
  end

  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  describe "message sending" do
    it "should start a group conversation when there is only one recipient" do
      get_conversations
      compose course: @course, to: [@s1], subject: 'single recipient', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('single recipient')
      expect(c.private?).to be_falsey
    end

    it "should start a group conversation when there is more than one recipient" do
      get_conversations
      compose course: @course, to: [@s1, @s2], subject: 'multiple recipients', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('multiple recipients')
      expect(c.private?).to be_falsey
      expect(c.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @s1, @s2].collect(&:id).sort)
    end

    it "should allow admins to send a message without picking a context" do
      user = account_admin_user
      user_logged_in({:user => user})
      get_conversations
      compose to: [@s1], subject: 'context-free', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq 'context-free'
      expect(c.context).to eq Account.default
    end

    it "should not allow non-admins to send a message without picking a context" do
      get_conversations
      fj('#compose-btn').click
      wait_for_animations
      expect(fj('#compose-new-message .ac-input')).to have_attribute(:disabled, 'true')
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
      expect(f('.ac-token')).not_to be_nil
    end

    it "should allow selecting multiple recipients in one search" do
      get_conversations
      fj('#compose-btn').click
      wait_for_ajaximations
      select_message_course(@course)
      get_message_recipients_input.send_keys('student')
      driver.action.key_down(modifier).perform
      keep_trying_until { fj(".ac-result:contains('first student')") }.click
      driver.action.key_up(modifier).perform
      fj(".ac-result:contains('second student')").click
      expect(ff('.ac-token').count).to eq 2
    end

    it "should not send the message on shift-enter" do
      get_conversations
      compose course: @course, to: [@s1], subject: 'context-free', body: 'hallo!', send: false
      driver.action.key_down(:shift).perform
      get_message_body_input.send_keys(:enter)
      driver.action.key_up(:shift).perform
      expect(fj('#compose-new-message:visible')).not_to be_nil
    end

    context "user notes" do
      before(:each) do
        @course.account.update_attribute(:enable_user_notes, true)
        user_session(@teacher)
        get_conversations
      end

      it "should be allowed on new private conversations with students" do
        compose course: @course, to: [@s1, @s2], body: 'hallo!', send: false

        checkbox = f(".user_note")
        expect(checkbox).to be_displayed
        checkbox.click

        count1 = @s1.user_notes.count
        count2 = @s2.user_notes.count
        click_send
        expect(@s1.user_notes.reload.count).to eq count1 + 1
        expect(@s2.user_notes.reload.count).to eq count2 + 1
      end

      it "should be allowed with student groups" do
        compose course: @course, to: [@group], body: 'hallo!', send: false

        checkbox = f(".user_note")
        expect(checkbox).to be_displayed
        checkbox.click

        count1 = @s1.user_notes.count
        click_send
        expect(@s1.user_notes.reload.count).to eq count1 + 1
      end

      it "should not be allowed if disabled" do
        @course.account.update_attribute(:enable_user_notes, false)
        get_conversations
        compose course: @course, to: [@s1], body: 'hallo!', send: false
        expect(f(".user_note")).not_to be_displayed
      end

      it "should not be allowed for students" do
        user_session(@s1)
        get_conversations
        compose course: @course, to: [@s2], body: 'hallo!', send: false
        expect(f(".user_note")).not_to be_displayed
      end

      it "should not be allowed with non-student recipient" do
        compose course: @course, to: [@teacher], body: 'hallo!', send: false
        expect(f(".user_note")).not_to be_displayed
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
      expect(fj('#compose-message-course')).to have_attribute(:disabled, 'true')
      expect(fj('#compose-message-course')).to have_value(@course.id.to_s)
      expect(fj('#compose-message-subject')).to have_attribute(:disabled, 'true')
      expect(fj('#compose-message-subject')).not_to be_displayed
      expect(fj('#compose-message-subject')).to have_value(@convo.subject)
      expect(fj('.message_subject_ro')).to be_displayed
      expect(fj('.message_subject_ro').text).to eq @convo.subject
    end

    it "should address replies to the most recent author by default" do
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      expect(ffj('input[name="recipients[]"]').length).to eq 1
      expect(fj('input[name="recipients[]"]')).to have_value(@s2.id.to_s)
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
      expect(ffj('.message-item-view').length).to eq initial_message_count + 1
      @convo.reload
      expect(@convo.conversation_messages.length).to eq initial_message_count + 1
    end

    it "should not allow adding recipients to private messages" do
      @convo.update_attribute(:private_hash, '12345')
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      expect(fj('.compose_form .ac-input-box.disabled')).not_to be_nil
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
      selected = expect(get_bootstrap_select_value(get_view_filter)).to eq 'inbox'
      expect(conversation_elements.size).to eq 2
    end

    it "should have an unread view" do
      get_conversations
      select_view('unread')
      expect(conversation_elements.size).to eq 1
    end

    it "should have an starred view" do
      get_conversations
      select_view('starred')
      expect(conversation_elements.size).to eq 2
    end

    it "should have an sent view" do
      get_conversations
      select_view('sent')
      expect(conversation_elements.size).to eq 3
    end

    it "should have an archived view" do
      get_conversations
      select_view('archived')
      expect(conversation_elements.size).to eq 1
    end

    it "should default to all courses view" do
      get_conversations
      selected = expect(get_bootstrap_select_value(get_course_filter)).to eq ''
      expect(conversation_elements.size).to eq 2
    end

    it "should truncate long course names" do
      @course.name = "this is a very long course name that will be truncated"
      @course.save!
      get_conversations
      select_course(@course.id)
      button_text = f('.filter-option', get_course_filter).text
      expect(button_text).not_to eq @course.name
      expect(button_text[0...5]).to eq @course.name[0...5]
      expect(button_text[-5..-1]).to eq @course.name[-5..-1]
    end

    it "should filter by course" do
      get_conversations
      select_course(@course.id)
      expect(conversation_elements.size).to eq 2
    end

    it "should filter by course plus view" do
      get_conversations
      select_course(@course.id)
      select_view('unread')
      expect(conversation_elements.size).to eq 1
    end

    it "should hide the spinner after deleting the last conversation" do
      get_conversations
      select_view('archived')
      expect(conversation_elements.size).to eq 1
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(conversation_elements.size).to eq 0
      expect(ffj('.message-list .paginatedLoadingIndicator:visible').length).to eq 0
      expect(ffj('.actions .btn-group button:disabled').size).to eq 4
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
      expect(star_btn).to be_present
      expect(f('.active', unstarred_elt)).to be_nil

      star_btn.click
      wait_for_ajaximations
      expect(f('.active', unstarred_elt)).to be_present
      expect(@conv_unstarred.reload.starred).to be_truthy
    end

    it "should unstar via star icon" do
      get_conversations
      starred_elt = conversation_elements[0]
      star_btn = f('.star-btn', starred_elt)
      expect(star_btn).to be_present
      expect(f('.active', starred_elt)).to be_present

      star_btn.click
      wait_for_ajaximations
      expect(f('.active', starred_elt)).to be_nil
      expect(@conv_starred.reload.starred).to be_falsey
    end

    it "should star via gear menu" do
      get_conversations
      unstarred_elt = conversation_elements[1]
      unstarred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      expect(f('.active', unstarred_elt)).to be_present
      run_progress_job
      expect(@conv_unstarred.reload.starred).to be_truthy
    end

    it "should unstar via gear menu" do
      get_conversations
      starred_elt = conversation_elements[0]
      starred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      expect(f('.active', starred_elt)).to be_nil
      run_progress_job
      expect(@conv_starred.reload.starred).to be_falsey
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
      expect(conversation_elements.length).to eq 1
    end
  end

  describe "multi-select" do
    before(:each) do
      @conversations = [conversation(@teacher, @s1, @s2, workflow_state: 'read'),
                        conversation(@teacher, @s1, @s2, workflow_state: 'read')]
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
      expect(ff('.messages li.active').count).to eq 2
    end

    it "should select all conversations" do
      get_conversations
      driver.action.key_down(modifier)
        .send_keys('a')
        .key_up(modifier)
        .perform
      expect(ff('.messages li.active').count).to eq 2
    end

    it "should archive multiple conversations" do
      get_conversations
      select_all_conversations
      f('#archive-btn').click
      wait_for_ajaximations
      expect(conversation_elements.count).to eq 0
      run_progress_job
      @conversations.each { |c| expect(c.reload).to be_archived }
    end

    it "should delete multiple conversations" do
      get_conversations
      select_all_conversations
      f('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(conversation_elements.count).to eq 0
    end

    it "should mark multiple conversations as unread" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_unread_toggle_menu_item
      keep_trying_until { expect(ffj('.read-state[aria-checked=false]').count).to eq 2 }
    end

    it "should mark multiple conversations as unread" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_read_toggle_menu_item
      keep_trying_until { expect(ffj('.read-state[aria-checked=true]').count).to eq 2 }
    end

    it "should star multiple conversations" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_star_toggle_menu_item
      run_progress_job
      keep_trying_until { expect(ff('.star-btn.active').count).to eq 2 }
      @conversations.each { |c| expect(c.reload).to be_starred }
    end
  end

  describe 'conversations inbox opt-out option' do
    it "should be hidden a feature flag" do
      get "/profile/settings"
      expect(ff('#disable_inbox').count).to eq 0
    end

    it "should reveal when the feature flag is set" do
      @course.root_account.enable_feature!(:allow_opt_out_of_inbox)
      get "/profile/settings"
      expect(ff('#disable_inbox').count).to eq 1
    end

    context "when activated" do
      it "should set the notification preferences for conversations to ASAP, and hide those options" do
        @course.root_account.enable_feature!(:allow_opt_out_of_inbox)
        expect(@teacher.reload.disabled_inbox?).to be_falsey
        notification = Notification.create!(workflow_state: "active", name: "Conversation Message",
                             category: "Conversation Message", delay_for: 0)
        policy = NotificationPolicy.create!(notification_id: notification.id, communication_channel_id: @teacher.email_channel.id, broadcast: true, frequency: "weekly")
        @teacher.update_attribute(:unread_conversations_count, 3)
        sleep 0.5

        get '/profile/communication'
        expect(ff('td[data-category="conversation_message"]').count).to eq 1
        expect(ff('.unread-messages-count').count).to eq 1

        get "/profile/settings"
        f('#disable_inbox').click
        sleep 0.5

        expect(@teacher.reload.disabled_inbox?).to be_truthy

        get '/profile/communication'
        expect(ff('td[data-category="conversation_message"]').count).to eq 0
        expect(policy.reload.frequency).to eq "immediately"
        expect(ff('.unread-messages-count').count).to eq 0
      end
    end
  end

  context 'submission comment stream items' do
    before do
      @course1 = @course
      @course2 = course(active_course: true)
      teacher_in_course(user: @teacher, course: @course2, active_all: true)
      student_in_course(user: @s1, active_all: true, course: @course1)
      student_in_course(user: @s2, active_all: true, course: @course2)

      def assignment_with_submission_comments(title, student, course)
        assignment = course.assignments.create!(:title => title, :description => 'hai', :points_possible => '14.2', :submission_types => 'online_text_entry')
        sub = assignment.grade_student(student, { :grade => '12', :grader => @teacher}).first
        sub.workflow_state = 'submitted'
        sub.submission_comments.create!(:comment => 'c1', :author => @teacher, :recipient_id => student.id)
        sub.submission_comments.create!(:comment => 'c2', :author => student, :recipient_id => @teacher.id)
        sub.save!
        sub
      end

      assignment_with_submission_comments('assignment 1', @s1, @course1)
      @submission = assignment_with_submission_comments('assignment 2', @s2, @course2)
    end

    describe 'view filter' do
      it 'shows submission comments' do
        get_conversations
        select_view('submission_comments')
        expect(conversation_elements.size).to eq 2
      end

      it 'filters by course' do
        get_conversations
        select_view('submission_comments')
        select_course(@course1.id)
        expect(conversation_elements.size).to eq 1
      end

      it 'filters by submitter' do
        get_conversations
        select_view('submission_comments')
        name = @s2.name
        f('[role=main] header [role=search] input').send_keys(name)
        keep_trying_until { fj(".ac-result:contains('#{name}')") }.click
        expect(conversation_elements.length).to eq 1
      end
    end

    it 'adds new messages to the view' do
      get_conversations
      select_view('submission_comments')
      initial_message_count = @submission.submission_comments.count
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#submission-reply-btn').click
      fj('.reply_body').send_keys('c3')
      fj('.submission-comment-reply-dialog .send-message').click
      wait_for_ajaximations
      expect(ffj('.message-item-view').length).to eq (initial_message_count + 1)
      expect(@submission.reload.submission_comments.count).to eq (initial_message_count + 1)
    end

    it 'marks unread on click' do
      expect(@submission.read?(@teacher)).to be_falsey
      get_conversations
      select_view('submission_comments')
      conversation_elements[0].click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_truthy
    end

    it 'marks an read/unread' do
      expect(@submission.read?(@teacher)).to be_falsey
      get_conversations
      select_view('submission_comments')
      toggle = fj('.read-state', conversation_elements[0])
      toggle.click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_truthy
      toggle.click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_falsey
    end
  end
end
