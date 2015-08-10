require File.expand_path(File.dirname(__FILE__) + '/../common')


def modifier
  @_modifier ||= determine_modifier
end

def determine_modifier
  if driver.execute_script('return !!window.navigator.userAgent.match(/Macintosh/)')
    :meta
  else
    :control
  end
end

def get_conversations
  get conversations_path
end

def conversation_setup
  course_with_teacher_logged_in

  term = EnrollmentTerm.new :name => "Super Term"
  term.root_account_id = @course.root_account_id
  term.save!

  @course.update_attributes! :enrollment_term => term

  @user.watched_conversations_intro
  @user.save
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

def select_message(msg_index)
  conversation_elements[msg_index].click
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

def select_conversations(to_select = -1)
  driver.action.key_down(modifier).perform
  messages = ff('.messages li')
  message_count = messages.length

  # default of -1 will select all messages. If you enter in too large of number, it defaults to selecting all
  to_select = message_count if (to_select == -1) || (to_select > ff('.messages li').length)

  index = 0
  messages.each do |message|
    message.click
    break if index > to_select
    index += 1
  end

  driver.action.key_up(modifier).perform
end

# Allows you to select between
def click_more_options(opts,message = 0)
  case
  # First case is for clicking on message gear menu
  when opts[:message]
    # The More Options gear menu only shows up on mouse over of message
    driver.mouse.move_to ff('.message-item-view')[message]
    wait_for_ajaximations
    f('.actions li .inline-block .al-trigger').click
  # This case is for clicking on gear menu at conversation heading level
  when opts[:convo]
    f('.message-header .al-trigger').click
  # Otherwise, it clicks the topmost gear menu
  else f('#admin-btn.al-trigger').click
  end
  wait_for_ajaximations
end

# Manually forwards a message. Thankfully, each More Option button has the same menu elements within
def forward_message(recipient)
  ffj('.ui-menu-item .ui-corner-all:visible')[1].click
  wait_for_ajaximations
  add_message_recipient recipient
  set_message_body('stuff')
  f('.btn-primary.send-message').click
  wait_for_ajaximations
end

def add_students(count)
  @s = []
  count.times do |n|
    @s << User.create!(:name => "Test Student #{n+1}")
    @course.enroll_student(@s.last).update_attribute(:workflow_state, 'active')
  end
end

def click_reply
  f('#reply-btn').click
  wait_for_ajaximations
end

def reply_to_message(body = 'stuff')
  click_reply
  set_message_body(body)
  click_send
end

# makes a message's star and unread buttons visible via mouse over
def hover_over_message(msg)
  driver.mouse.move_to(msg)
  wait_for_ajaximations
end

def click_star_icon(msg,star_btn = nil)
  if star_btn == nil
    star_btn = f('.star-btn', msg)
  end

  star_btn.click
  wait_for_ajaximations
end

# Clicks the admin archive/unarchive button
def click_archive_button
  f('#archive-btn').click
  wait_for_ajaximations
end

# Clicks star cog menu item
def click_archive_menu_item
  f('.archive-btn.ui-corner-all').click
  wait_for_ajaximations
end

def click_message(msg)
  conversation_elements[msg].click
  wait_for_ajaximations
end