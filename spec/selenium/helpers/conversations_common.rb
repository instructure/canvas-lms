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
  wait_for_ajaximations
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