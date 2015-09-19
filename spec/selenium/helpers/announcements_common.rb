require File.expand_path(File.dirname(__FILE__) + '/../common')

def create_announcement(title = 'announcement title', message = 'announcement message')
  @context = @course
  @announcement = announcement_model(:title => title, :message => message)
end

def create_announcement_initial(message = 'announcement message')
  @context = @course
  @announcement =  announcement_model(:title => 'new announcement', :message => message, :require_initial_post => true)
end

def create_announcement_manual(title,text)
  get "/courses/#{@course.id}/announcements/"
  expect_new_page_load { f('.btn-primary').click }
  replace_content(f('input[name=title]'), title)
  type_in_tiny('textarea[name=message]', text)
  expect_new_page_load { submit_form('.form-actions') }
end

def create_announcement_option(css_checkbox)
  expect_new_page_load { f('.btn-primary').click }
  replace_content(f('input[name=title]'), "First Announcement")

  type_in_tiny('textarea[name=message]', 'Hi, this is my first announcement')
  if css_checkbox != nil
    f(css_checkbox).click
  end
end

def reply_to_announcement(announcement_id, text)
  get "/courses/#{@course.id}/discussion_topics/#{announcement_id}"
  f('.discussion-reply-action').click
  wait_for_ajaximations
  type_in_tiny('textarea', text)
  submit_form('#discussion_topic .discussion-reply-form')
  wait_for_ajaximations
end

def update_attributes_and_validate(attribute, update_value, search_term = update_value, expected_results = 1)
  what_to_create.last.update_attributes(attribute => update_value)
  refresh_page # in order to get the new topic information
  replace_content(f('#searchTerm'), search_term)
  expect(ff('.discussionTopicIndexList .discussion-topic').count).to eq expected_results
end

def refresh_and_filter(filter_type, filter, expected_text, expected_results = 1)
  refresh_page # in order to get the new topic information
  wait_for_ajaximations
  keep_trying_until { expect(ff('.toggleSelected').count).to eq what_to_create.count }
  filter_type == :css ? driver.execute_script("$('#{filter}').click()") : replace_content(f('#searchTerm'), filter)
  expect(ff('.discussionTopicIndexList .discussion-topic').count).to eq expected_results
  expected_results > 1 ? ff('.discussionTopicIndexList .discussion-topic').each { |topic| expect(topic).to include_text(expected_text) } : (expect(f('.discussionTopicIndexList .discussion-topic')).to include_text(expected_text))
end

def add_attachment_and_validate
  filename, fullpath, data = get_file("testfile5.zip")
  f('input[name=attachment]').send_keys(fullpath)
  type_in_tiny('textarea[name=message]', 'file attachement discussion')
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

# DRY method that checks that a group member can see all announcements created within a group
#   and that clicking one takes you to it. Expects @announcement is defined and count is > 0
def verify_member_sees_announcement(count = 1)
  index = count-1
  get announcements_page
  expect(ff('.discussion-topic').size).to eq count
  # Checks that new page is loaded when the indexed announcement is clicked to verify it actually loads the topic
  expect_new_page_load { ff('.discussion-topic')[index].click }
  # Checks that the announcement is there by verifying the title is present and correct
  expect(f('.discussion-title')).to include_text("#{@announcement.title}")
end

def delete_announcement_via_gear_menu(num = 0)
  # Clicks the gear menu for announcement num
  ff('.al-trigger-gray')[num].click
  wait_for_ajaximations
  # Clicks delete menu item
  f('.icon-trash.ui-corner-all').click
  driver.switch_to.alert.accept
  wait_for_animations
end

# Clicks edit button on Announcement show page
def click_edit_btn
  f('.edit-btn').click
  wait_for_ajaximations
end