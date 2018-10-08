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

require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')
require_relative '../discussions/pages/discussion_page.rb'

describe "reply attachment" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before() do
    @topic_title = 'discussion topic'
    course_with_teacher_logged_in
    @topic = create_discussion(@topic_title, 'threaded')
    @student = student_in_course.user
  end

  it "should create a discussion" do
    Discussion.visit(@course, @topic)

    expect(f('.discussion-title').text).to eq @topic_title
  end

  it "should allow reply after cancel" do
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    f('.discussion-reply-box').click
    wait_for_ajaximations
    f('.cancel_button').click
    f('.discussion-reply-box').click
    wait_for_ajaximations
    begin
      tinymce = f('.mce-tinymce')
      expect(tinymce.enabled?).to eq true
    rescue Selenium::WebDriver::Error::NoSuchElementError
      expect("tinymce not loaded").to eq "loaded"
    end
  end

  it "should reply to the discussion with attachment" do
    file_attachment = "graded.png"
    entry_text = 'new entry'
    Discussion.visit(@course, @topic)

    add_reply(entry_text, file_attachment)
    expect(get_all_replies.count).to eq 1

    expect(@last_entry.find_element(:css, '.message').text).to eq entry_text
    expect(@last_entry.find_element(:css, '.comment_attachments a.image')).to be_displayed
  end

  it "should delete the attachment from the reply" do
    skip_if_chrome('Cancel button click does not reliably happen')
    file_attachment = "graded.png"
    entry_text = 'new entry'
    Discussion.visit(@course, @topic)

    add_reply(entry_text, file_attachment)

    # open the gear menu
    @last_entry.find_element(:css, '.admin-links a').click
    # click on edit
    @last_entry.find_element(:css, '.al-options li.ui-menu-item:nth-of-type(2)').click
    # click on the cancel attachment button
    @last_entry.find_element(:css, '.comment_attachments .cancel_button').click
    # the attachment is hidden
    expect(@last_entry.find_element(:css, '.comment_attachments > div').displayed?).to be(false)

    # click Done
    @last_entry.find_element(:css, '.edit_html_done').click
    # attachment is gone
    expect(@last_entry).not_to contain_css('.comment_attachments')
  end

  it 'media attachment modal can be opened' do
    Account.default.enable_feature!(:integrate_arc_rce)
    Discussion.visit(@course, @topic)
    Discussion.start_reply_with_media
    expect(Discussion.media_modal).to be_displayed
  end
end
