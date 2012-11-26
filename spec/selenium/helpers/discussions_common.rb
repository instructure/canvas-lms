require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_examples_for "discussions selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def create_and_go_to_topic(title = 'new topic', discussion_type = 'side_comment', is_locked = false)
    topic = @course.discussion_topics.create!(:title => title, :discussion_type => discussion_type)
    if is_locked
      topic.workflow_state = 'locked'
      topic.save!
      topic.reload
    end
    get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
    wait_for_ajax_requests
    topic
  end

  def create_discussion(discussion_name, discussion_type)
    @course.discussion_topics.create!(:title => discussion_name, :discussion_type => discussion_type)
  end

  def edit_topic(discussion_name, message)
    replace_content(f('input[name=title]'), discussion_name)
    type_in_tiny('textarea[name=message]', message)
    expect_new_page_load { submit_form('.form-actions') }
    f('#discussion_topic .discussion-title').text.should == discussion_name
  end

  def edit_entry(entry, text)
    click_entry_option(entry, '.al-options:visible li:eq(1) a')
    type_in_tiny 'textarea', text
    f('.edit-html-done').click
    wait_for_ajax_requests
    validate_entry_text(entry, text)
  end

  def delete_entry(entry)
    keep_trying_until do
      click_entry_option(entry, '.al-options:visible li:last-child a')
      validate_entry_text(entry, "This entry has been deleted")
      entry.save!
      entry.reload
      entry.workflow_state.should == 'deleted'
    end
  end

  def add_reply(message = 'message!', attachment = nil)
    @last_entry ||= f('#discussion_topic')
    @last_entry.find_element(:css, '.discussion-reply-label').click
    type_in_tiny 'textarea', message

    if attachment.present?
      filename, fullpath, data = get_file(attachment)
      @last_entry.find_element(:css, '.discussion-reply-add-attachment').click
      @last_entry.find_element(:css, '.discussion-reply-attachments input').send_keys(fullpath)
    end

    submit_form('.discussion-reply-form')
    wait_for_ajax_requests
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
      f("#entry-#{discussion_entry.id}").should include_text(text)
    end
  end

  def click_entry_option(discussion_entry, menu_item_selector)
    li_selector = "#entry-#{discussion_entry.id}"
    fj(li_selector).should be_displayed
    fj("#{li_selector} .al-trigger").should be_displayed
    fj("#{li_selector} .al-trigger").click
    menu_item = fj(menu_item_selector)
    menu_item.should be_displayed
    menu_item.click
  end

  def click_topic_option(topic_selector, menu_item_selector)
    topic = f(topic_selector)
    topic.find_element(:css, '.al-trigger').click
    fj(menu_item_selector).click
    topic
  end
end
