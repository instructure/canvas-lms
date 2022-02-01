# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../helpers/discussions_common"
require_relative "../discussions/pages/discussion_page"

describe "reply attachment" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before do
    @topic_title = "discussion topic"
    course_with_teacher_logged_in
    @topic = create_discussion(@topic_title, "threaded")
    @student = student_in_course.user
  end

  before do
    stub_rcs_config
  end

  context "when react_discussions_post ff is OFF" do
    before :once do
      Account.site_admin.disable_feature! :react_discussions_post
    end

    it "allows reply after cancel" do
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f(".discussion-reply-box").click
      wait_for_tiny(f("#root_reply_message_for_#{@topic.id}"))
      f(".cancel_button").click
      force_click(".discussion-reply-box")
      wait_for_ajaximations
      begin
        tinymce = f(".tox-tinymce")
        expect(tinymce.enabled?).to eq true
      rescue Selenium::WebDriver::Error::NoSuchElementError
        expect("tinymce not loaded").to eq "loaded"
      end
    end

    it "replies to the discussion with attachment" do
      file_attachment = "graded.png"
      entry_text = "new entry"
      Discussion.visit(@course, @topic)

      add_reply(entry_text, file_attachment)
      expect(get_all_replies.count).to eq 1

      expect(@last_entry.find_element(:css, ".message").text).to eq entry_text
      expect(@last_entry.find_element(:css, ".comment_attachments a.image")).to be_displayed
    end

    it "deletes the attachment from the reply" do
      skip_if_chrome("Cancel button click does not reliably happen")
      file_attachment = "graded.png"
      entry_text = "new entry"
      Discussion.visit(@course, @topic)

      add_reply(entry_text, file_attachment)

      # open the gear menu
      @last_entry.find_element(:css, ".admin-links a").click
      # click on edit
      @last_entry.find_element(:css, ".al-options li.ui-menu-item:nth-of-type(2)").click
      # click on the cancel attachment button
      @last_entry.find_element(:css, ".comment_attachments .cancel_button").click
      # the attachment is hidden
      expect(@last_entry.find_element(:css, ".comment_attachments > div").displayed?).to be(false)

      # click Done
      @last_entry.find_element(:css, ".edit_html_done").click
      # attachment is gone
      expect(@last_entry).not_to contain_css(".comment_attachments")
    end
  end

  context "when react_discussions_post ff is ON" do
    before :once do
      Account.site_admin.enable_feature! :react_discussions_post
    end

    it "can view and delete legacy reply attachments" do
      entry = @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student",
        attachment: attachment_model
      )

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      attachment_link = fj("a:contains('#{entry.attachment.filename}')")
      expect(attachment_link).to be_truthy
      expect(attachment_link.attribute("href")).to include("/files/#{entry.attachment.id}")

      f("button[data-testid='thread-actions-menu']").click
      fj("li:contains('Edit')").click
      driver.action.move_to(fj("a:contains('#{entry.attachment.filename}')")).perform # hover
      f("button[data-testid='remove-button']").click
      expect(f("body")).not_to contain_jqcss("a:contains('#{entry.attachment.filename}')")
      fj("button:contains('Save')").click
      wait_for_ajaximations
      expect(f("body")).not_to contain_jqcss("a:contains('#{entry.attachment.filename}')")
    end
  end
end
