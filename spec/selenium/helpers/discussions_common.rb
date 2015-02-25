require File.expand_path(File.dirname(__FILE__) + '/../common')


  def go_to_topic
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
  end

  def create_and_go_to_topic(title = 'new topic', discussion_type = 'side_comment', is_locked = false)
    @topic = @course.discussion_topics.create!(:title => title, :discussion_type => discussion_type)
    if is_locked
      @topic.lock
      @topic.reload
    end
    go_to_topic
    @topic
  end

  def create_discussion(discussion_name, discussion_type)
    @course.discussion_topics.create!(:title => discussion_name, :discussion_type => discussion_type)
  end

  def edit_topic(discussion_name, message)
    replace_content(f('input[name=title]'), discussion_name)
    type_in_tiny('textarea[name=message]', message)
    expect_new_page_load { submit_form('.form-actions') }
    expect(f('#discussion_topic .discussion-title').text).to eq discussion_name
  end

  def edit_entry(entry, text)
    wait_for_ajaximations
    click_entry_option(entry, '.al-options:visible li:eq(1) a')
    wait_for_ajaximations
    type_in_tiny 'textarea', text
    f('.edit-html-done').click
    wait_for_ajaximations
    validate_entry_text(entry, text)
  end

  def delete_entry(entry)
    wait_for_ajaximations
    click_entry_option(entry, '.al-options:visible li:last-child a')
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.accept
    wait_for_ajax_requests
    entry.reload
    expect(entry.workflow_state).to eq 'deleted'
  end

  def add_reply(message = 'message!', attachment = nil)
    @last_entry ||= f('#discussion_topic')
    @last_entry.find_element(:css, '.discussion-reply-action').click
    wait_for_ajaximations
    type_in_tiny 'textarea', message

    if attachment.present?
      filename, fullpath, data = get_file(attachment)
      @last_entry.find_element(:css, '.discussion-reply-add-attachment').click
      wait_for_ajaximations
      @last_entry.find_element(:css, '.discussion-reply-attachments input').send_keys(fullpath)
    end

    submit_form('.discussion-reply-form')
    wait_for_ajaximations
    keep_trying_until do
      id = DiscussionEntry.last.id
      @last_entry = f "#entry-#{id}"
    end
  end

  def get_all_replies
    ff('#discussion_subentries .discussion_entry')
  end

  def validate_entry_text(discussion_entry, text)
    keep_trying_until do
      expect(f("#entry-#{discussion_entry.id}")).to include_text(text)
    end
  end

  def click_entry_option(discussion_entry, menu_item_selector)
    li_selector = "#entry-#{discussion_entry.id}"
    expect(fj(li_selector)).to be_displayed
    expect(fj("#{li_selector} .al-trigger")).to be_displayed
    fj("#{li_selector} .al-trigger").click
    wait_for_ajaximations
    menu_item = fj(menu_item_selector)
    expect(menu_item).to be_displayed
    menu_item.click
  end

  def click_topic_option(topic_selector, menu_item_selector)
    topic = f(topic_selector)
    topic.find_element(:css, '.al-trigger').click
    fj(menu_item_selector).click
    topic
  end

def set_checkbox(selector, check)
  fj(selector + (check ? ':not(:checked)' : ':checked')).try(:click)
end

def filter(opts)
  replace_content(f('#searchTerm'), opts[:term] || '')
  set_checkbox('#onlyGraded', opts[:only_graded])
  set_checkbox('#onlyUnread', opts[:only_unread])
  wait_for_animations
end

def index_is_showing?(*topics)
  ffj('.discussion-list li.discussion:visible').count == topics.size &&
      topics.all? { |t| topic_index_element(t).try(:displayed?) }
end

def add_attachment_and_validate
  filename, fullpath, data = get_file("testfile5.zip")
  f('input[name=attachment]').send_keys(fullpath)
  type_in_tiny('textarea[name=message]', 'file attachement discussion')
  yield if block_given?
  expect_new_page_load { submit_form('.form-actions') }
  wait_for_ajaximations
  expect(f('.zip')).to include_text(filename)
end

def edit(title, message)
  replace_content(f('input[name=title]'), title)
  type_in_tiny('textarea[name=message]', message)
  expect_new_page_load { submit_form('.form-actions') }
  expect(f('#discussion_topic .discussion-title').text).to eq title
end

def topic_index_element(topic)
  fj(".discussion[data-id='#{topic.id}']")
end

def check_permissions(number_of_checkboxes = 1)
  get url
  wait_for_ajaximations
  checkboxes = ff('.discussion .al-trigger')
  expect(checkboxes.length).to eq number_of_checkboxes
  expect(ff('.discussion-list li.discussion').length).to eq DiscussionTopic.count
end

def topic_for_filtering(opts={})
  name = "#{opts[:graded] ? 'graded' : 'ungraded'} #{opts[:read] ? 'read' : 'unread'} topic"
  if opts[:graded]
    a = course.assignments.create!(name:  name + ' assignment', submission_types: 'discussion_topic', assignment_group: assignment_group)
    dt = a.discussion_topic
    dt.title = name + ' title'
    dt.save!
  else
    dt = course.discussion_topics.create!(user: student, title: name + ' title', message: name + ' message')
  end
  dt.change_read_state(opts[:read] ? 'read' : 'unread', somebody)
  dt
end

def click_publish_icon(topic)
  get url
  fj(".discussion[data-id=#{topic.id}] .publish-icon i").click
  wait_for_ajaximations
end

def confirm(state)
  checkbox_state = state == :on ? 'true' : nil
  get url
  wait_for_ajaximations

  expect(f('input[type=checkbox][name=threaded]')[:checked]).to eq checkbox_state
  expect(f('input[type=checkbox][name=require_initial_post]')[:checked]).to eq checkbox_state
  expect(f('input[type=checkbox][name=podcast_enabled]')[:checked]).to eq checkbox_state
  expect(f('input[type=checkbox][name=podcast_has_student_posts]')[:checked]).to eq checkbox_state
  expect(f('input[type=checkbox][name="assignment[set_assignment]"]')[:checked]).to eq checkbox_state
end

def toggle(state)
  f('input[type=checkbox][name=threaded]').click
  set_value f('input[name=delayed_post_at]'), 2.weeks.from_now.strftime('%m/%d/%Y') if state == :on
  f('input[type=checkbox][name=require_initial_post]').click
  f('input[type=checkbox][name=podcast_enabled]').click
  f('input[type=checkbox][name=podcast_has_student_posts]').click if state == :on
  f('input[type=checkbox][name="assignment[set_assignment]"]').click

  expect_new_page_load { f('.form-actions button[type=submit]').click }
  wait_for_ajaximations
end