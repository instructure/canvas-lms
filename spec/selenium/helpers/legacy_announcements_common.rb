# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../common"

module AnnouncementsCommon
  def create_announcement(title = "announcement title", message = "announcement message")
    @context = @course
    @announcement = announcement_model(title:, message:)
  end

  def create_announcement_initial(message = "announcement message")
    @context = @course
    @announcement = announcement_model(title: "new announcement", message:, require_initial_post: true)
  end

  def create_announcement_manual(title, text)
    get "/courses/#{@course.id}/announcements/"
    expect_new_page_load { f(".btn-primary").click }
    replace_content(f("input[name=title]"), title)
    type_in_tiny("textarea[name=message]", text)
    expect_new_page_load { submit_form(".form-actions") }
  end

  def create_announcement_option(css_checkbox)
    expect_new_page_load { f(".btn-primary").click }
    replace_content(f("input[name=title]"), "First Announcement")

    type_in_tiny("textarea[name=message]", "Hi, this is my first announcement")
    f(css_checkbox).click unless css_checkbox.nil?
  end

  def reply_to_announcement(announcement_id, text)
    get "/courses/#{@course.id}/discussion_topics/#{announcement_id}"
    f(".discussion-reply-action").click
    wait_for_ajaximations
    type_in_tiny("textarea", text)
    submit_form("#discussion_topic .discussion-reply-form")
    wait_for_ajaximations
  end

  def update_attributes_and_validate(attribute, update_value, search_term = update_value, expected_results = 1)
    what_to_create.last.update(attribute => update_value)
    refresh_page # in order to get the new topic information
    replace_content(f("#searchTerm"), search_term)
    expect(ff(".discussionTopicIndexList .discussion-topic").count).to eq expected_results
  end

  def refresh_and_filter(filter_type, filter, expected_text, expected_results = 1)
    refresh_page # in order to get the new topic information
    expect(ff(".toggleSelected")).to have_size(what_to_create.count)
    (filter_type == :css) ? fj(filter).click : replace_content(f("#searchTerm"), filter)
    expect(ff(".discussionTopicIndexList .discussion-topic").count).to eq expected_results
    (expected_results > 1) ? ff(".discussionTopicIndexList .discussion-topic").each { |topic| expect(topic).to include_text(expected_text) } : (expect(f(".discussionTopicIndexList .discussion-topic")).to include_text(expected_text))
  end

  def add_attachment_and_validate
    filename, fullpath, _data = get_file("testfile5.zip")
    f("input[name=attachment]").send_keys(fullpath)
    type_in_tiny("textarea[name=message]", "file attachement discussion")
    expect_new_page_load { submit_form(".form-actions") }
    wait_for_ajaximations
    expect(f(".zip")).to include_text(filename)
  end

  def edit_announcement(title, message)
    wait_for_tiny(f("textarea[name=message]"))
    replace_content(f("input[name=title]"), title)
    type_in_tiny("textarea[name=message]", message)
    expect_new_page_load { submit_form(".form-actions") }
    expect(f("#discussion_topic .discussion-title").text).to eq title
  end

  # DRY method that checks that a group member can see all announcements created within a group
  #   and that clicking one takes you to it. Expects @announcement is defined and count is > 0
  def verify_member_sees_announcement(count = 1)
    index = count - 1
    get announcements_page
    expect(ff(".discussion-topic").size).to eq count
    # Checks that new page is loaded when the indexed announcement is clicked to verify it actually loads the topic
    expect_new_page_load { ff(".discussion-topic")[index].click }
    # Checks that the announcement is there by verifying the title is present and correct
    expect(f(".discussion-title")).to include_text(@announcement.title)
  end

  # Clicks edit button on Announcement show page
  def click_edit_btn
    f(".edit-btn").click
    wait_for_ajaximations
  end

  # sets the course setting checkbox for 'Disable comments on announcements'
  def disable_comments_on_announcements(set = true)
    @course.lock_all_announcements = set
    @course.save!
  end
end
