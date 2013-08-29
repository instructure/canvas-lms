require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations new" do
  it_should_behave_like "in-process server selenium tests"

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

  def click_star_toggle_menu_item()
    f('#admin-btn').click
    f("#star-toggle-btn").click
    wait_for_ajaximations
  end

  def select_message_course(new_course)
    new_course = new_course.name if new_course.respond_to? :name
    fj('.dropdown-toggle', get_message_course).click
    fj("a:contains('#{new_course}')", get_message_course).click
  end

  def add_message_recipient(to)
    to = to.name if to.respond_to?(:name)
    get_message_recipients_input.send_keys(to)
    keep_trying_until { fj(".ac-result:contains('#{to}')") }.click
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
    wait_for_animations
    select_message_course(options[:course]) if options[:course]
    (options[:to] || []).each {|recipient| add_message_recipient recipient}
    set_message_subject(options[:subject]) if options[:subject]
    set_message_body(options[:body]) if options[:body]
    click_send if options[:send].nil? || options[:send]
  end

  before do
    conversation_setup
    @teacher.preferences[:use_new_conversations] = true
    @teacher.save!

    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
  end

  describe "message sending" do
    it "should start a group conversation when there is only one recipient" do
      get_conversations
      compose course: @course, to: [@s1], subject: 'single recipient', body: 'hallo!'
      c = @s1.conversations.last.conversation
      c.subject.should eql('single recipient')
      c.private?.should be_false
    end

    it "should start a group conversation when there is more than one recipient" do
      get_conversations
      compose course: @course, to: [@s1, @s2], subject: 'multiple recipients', body: 'hallo!'
      c = @s1.conversations.last.conversation
      c.subject.should eql('multiple recipients')
      c.private?.should be_false
      c.conversation_participants.collect(&:user_id).sort.should eql([@teacher, @s1, @s2].collect(&:id).sort)
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
      selected = get_bootstrap_select_value(get_view_filter).should eql 'inbox'
      conversation_elements.size.should eql 2
    end

    it "should have an unread view" do
      get_conversations
      select_view('unread')
      conversation_elements.size.should eql 1
    end

    it "should have an starred view" do
      get_conversations
      select_view('starred')
      conversation_elements.size.should eql 2
    end

    it "should have an sent view" do
      get_conversations
      select_view('sent')
      conversation_elements.size.should eql 3
    end

    it "should have an archived view" do
      get_conversations
      select_view('archived')
      conversation_elements.size.should eql 1
    end

    it "should default to all courses view" do
      get_conversations
      selected = get_bootstrap_select_value(get_course_filter).should eql ''
      conversation_elements.size.should eql 2
    end

    it "should truncate long course names" do
      @course.name = "this is a very long course name that will be truncated"
      @course.save!
      get_conversations
      select_course(@course.id)
      button_text = f('.filter-option', get_course_filter).text
      button_text.should_not eql @course.name
      button_text[0...5].should eql @course.name[0...5]
      button_text[-5..-1].should eql @course.name[-5..-1]
    end

    it "should filter by course" do
      get_conversations
      select_course(@course.id)
      conversation_elements.size.should eql 2 
    end

    it "should filter by course plus view" do
      get_conversations
      select_course(@course.id)
      select_view('unread')
      conversation_elements.size.should eql 1 
    end

    it "should hide the spinner after deleting the last conversation" do
      get_conversations
      select_view('archived')
      conversation_elements.size.should eql 1
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      conversation_elements.size.should eql 0
      ffj('.message-list .paginatedLoadingIndicator:visible').length.should eql 0
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
      @conv_unstarred.reload.starred.should be_true
    end

    it "should unstar via gear menu" do
      get_conversations
      starred_elt = conversation_elements[0]
      starred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      f('.active', starred_elt).should be_nil
      @conv_starred.reload.starred.should be_false
    end
  end

end
