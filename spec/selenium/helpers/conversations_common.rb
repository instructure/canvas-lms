#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../common')

module ConversationsCommon
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

  def conversations
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

  def view_filter
    driver.find_element(:id, 'conversation_filter_select')
  end

  def selected_view_filter
    select = view_filter
    options = select.find_elements(tag_name: 'option')
    selected = options.select(&:selected?)

    # should be one filter applied i every situation
    expect(selected.size).to eq 1
    value = selected[0].attribute('value')
    value
  end

  def course_filter
    skip('course filter selector fails intermittently (stale element reference), probably due to dynamic loading and refreshing')
    # try to make it load the courses first so it doesn't randomly refresh
    selector = '.course-filter.bootstrap-select'
    driver.execute_script(%{$('#{selector}').focus();})
    wait_for_ajaximations
    f(selector)
  end

  def message_course
    fj('.message_course.bootstrap-select')
  end

  def message_recipients_input
    fj('.compose_form #compose-message-recipients')
  end

  def message_subject_input
    fj('#compose-message-subject')
  end

  def message_body_input
    fj('.conversation_body')
  end

  def bootstrap_select_value(element)
    f('.selected .text', element).attribute('data-value')
  end

  def set_bootstrap_select_value(element, new_value)
    f('.dropdown-toggle', element).click()
    f(%{.text[data-value="#{new_value}"]}, element).click()
  end

  def select_view(new_view)
    view_filter.find_element(:css, "option[value='#{new_view}']").click
    wait_for_ajaximations
  end

  def select_course(new_course)
    set_bootstrap_select_value(course_filter, new_course)
    wait_for_ajaximations
  end

  def select_message(msg_index)
    conversation_elements[msg_index].click
    wait_for_ajaximations
  end

  def go_to_inbox_and_select_message
    conversations
    select_message(0)
  end

  def assert_number_of_recipients(num_of_recipients)
    expect(ff('input[name="recipients[]"]').length).to eq num_of_recipients
    expect(ff('input[name="recipients[]"]').first).to have_value(@s2.id.to_s)
    expect(ff('input[name="recipients[]"]').last).to have_value(@s1.id.to_s) if num_of_recipients > 1
  end

  def click_star_toggle_menu_item
    hover_and_click '#admin-btn'
    hover_and_click '#star-toggle-btn:visible'
    wait_for_ajaximations
  end

  def click_unread_toggle_menu_item
    hover_and_click '#admin-btn'
    hover_and_click '#mark-unread-btn:visible'
    wait_for_ajaximations
  end

  def click_read_toggle_menu_item
    hover_and_click '#admin-btn'
    hover_and_click '#mark-read-btn:visible'
    wait_for_ajaximations
  end

  def select_message_course(new_course, is_group = false)
    new_course = new_course.name if new_course.respond_to? :name
    fj('.dropdown-toggle', message_course).click
    if is_group
      wait_for_ajaximations
      fj("a:contains('Groups')", message_course).click
    end
    fj("a:contains('#{new_course}')", message_course).click
  end

  def add_message_recipient(to)
    synthetic = !(to.instance_of?(User) || to.instance_of?(String))
    to = to.name if to.respond_to?(:name)
    message_recipients_input.send_keys(to)
    fj(".ac-result:contains('#{to}')").click
    return unless synthetic
    fj(".ac-result:contains('All in #{to}')").click
  end

  def reply_to_submission_comment(message = "test")
    f('#submission-reply-btn').click
    f('.reply_body').send_keys(message)
    f('.submission-comment-reply-dialog .send-message').click
    wait_for_ajaximations
  end

  def write_message_subject(subject)
    message_subject_input.send_keys(subject)
  end

  def write_message_body(body)
    message_body_input.send_keys(body)
  end

  def click_faculty_journal # if the checkbox is not visible then end otherwise check it
    checkbox = 'div.message-header-row:nth-child(5) > div:nth-child(2) > label:nth-child(2)'
    f('.user_note').click if fj("#{checkbox}:visible")
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
    write_message_subject(options[:subject]) if options[:subject]
    write_message_body(options[:body]) if options[:body]
    click_faculty_journal if options[:journal]
    click_send if options[:send].nil? || options[:send]
  end

  def run_progress_job
    return unless progress = Progress.where(tag: 'conversation_batch_update').first
    job = Delayed::Job.find(progress.delayed_job_id)
    job.invoke_job
  end

  def select_conversations(to_select = -1)
    driver.action.key_down(modifier).perform
    messages = ff('.messages > li')
    message_count = messages.length

    # default of -1 will select all messages. If you enter in too large of number, it defaults to selecting all
    to_select = message_count if (to_select == -1) || (to_select > message_count)

    index = 0
    messages.each do |message|
      message.click
      index += 1
      break if index >= to_select
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
    write_message_body('stuff')
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
    write_message_body(body)
    click_send
  end

  # makes a message's star and unread buttons visible via mouse over
  def hover_over_message(msg)
    driver.mouse.move_to(msg)
    wait_for_ajaximations
  end

  def click_star_icon(msg,star_btn = nil)
    if star_btn.nil?
      star_btn = f('.star-btn', msg)
    end

    star_btn.click
    wait_for_ajaximations
  end

  # Clicks the admin archive/unarchive button
  def click_archive_button
    f('#archive-btn').click
    driver.switch_to.alert.accept
    wait_for_ajaximations
  end

  # Clicks star cog menu item
  def click_archive_menu_item
    f('.archive-btn.ui-corner-all').click
    driver.switch_to.alert.accept
    wait_for_ajaximations
  end

  def click_message(msg)
    conversation_elements[msg].click
    wait_for_ajaximations
  end
end
