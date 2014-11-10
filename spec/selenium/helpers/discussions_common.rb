require File.expand_path(File.dirname(__FILE__) + '/../common')


  def go_to_topic
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajaximations
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
