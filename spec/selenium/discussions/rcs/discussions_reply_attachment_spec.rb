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

require File.expand_path(File.dirname(__FILE__) + '/../../helpers/discussions_common')

describe "reply attachment" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before() do
    @topic_title = 'discussion topic'
    course_with_teacher_logged_in
    stub_rcs_config
    @topic = create_discussion(@topic_title, 'threaded')
    @student = student_in_course.user
  end

  it "should reply to the discussion with attachment" do
    file_attachment = "graded.png"
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    add_reply(entry_text, file_attachment)
    expect(get_all_replies.count).to eq 1

    expect(@last_entry.find_element(:css, '.message').text).to eq entry_text
    expect(@last_entry.find_element(:css, '.comment_attachments a.image')).to be_displayed
  end

  it "should delete the attachment from the reply" do
    skip_if_chrome('Cancel button click does not reliably happen')
    file_attachment = "graded.png"
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

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
end
