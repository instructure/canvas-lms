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

require File.expand_path(File.dirname(__FILE__) + '/../../helpers/discussions_common')

describe "threaded discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before :once do
    course_with_teacher(active_course: true, active_all: true, name: 'teacher')
    @topic_title = 'threaded discussion topic'
    @topic = create_discussion(@topic_title, 'threaded')
    @student = student_in_course(course: @course, name: 'student', active_all: true).user
  end

  before(:each) do
    user_session(@teacher)
    Account.default.enable_feature!(:rce_enhancements)
    stub_rcs_config
  end

  it "should reply to the threaded discussion", priority: "2", test_id: 222519 do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    add_reply(entry_text)
    last_entry = DiscussionEntry.last
    expect(get_all_replies.count).to eq 1
    expect(@last_entry.find_element(:css, '.message').text).to eq entry_text
    expect(last_entry.depth).to eq 1
  end

  it "should reply with iframe element" do
    entry_text = "<iframe src='https://example.com'></iframe>"
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    f('#discussion_topic').find_element(:css, '.discussion-reply-action').click
    wait_for_ajaximations
    f('[data-btn-id="rce-edit-btn"]').click
    wait_for_ajaximations
    f("textarea[data-rich_text='true']").send_keys entry_text
    fj("button:contains('Post Reply')").click
    wait_for_ajaximations
    expect(get_all_replies.count).to eq 1
    expect(f("iframe[src='https://example.com']")).to be_present
  end

  it "should allow edits to entries with replies", priority: "2", test_id: 222520 do
    skip_if_chrome('Type in tiny fails in chrome')
    edit_text = 'edit message'
    entry       = @topic.discussion_entries.create!(user: @student,
                                                    message: 'new threaded reply from student')
    child_entry = @topic.discussion_entries.create!(user: @student,
                                                    message: 'new threaded child reply from student',
                                                    parent_entry: entry)
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
    expect(entry.reload.message).to match(edit_text)
  end

  it "should edit a reply", priority: "1", test_id: 150514 do
    skip_if_chrome('Type in tiny fails in chrome')
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
  end

  it "should display editor name and timestamp after edit", priority: "2", test_id: 222522 do
    skip_if_chrome('needs research: passes locally fails on Jenkins ')
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
    wait_for_ajaximations
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
  end

  it "should support repeated editing", priority: "2", test_id: 222523 do
    skip_if_chrome('Type in tiny fails in chrome')
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, 'New text 1')
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
    # second edit
    edit_entry(entry, 'New text 2')
    entry.reload
    expect(entry.message).to match 'New text 2'
  end

  it "should re-render replies after editing", priority: "2", test_id: 222524 do
    skip_if_chrome('Type in tiny fails in chrome')
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    @last_entry = f("#entry-#{entry.id}")
    reply_text = "this is a reply"
    add_reply(reply_text)
    expect { DiscussionEntry.count }.to become(2)
    subentry = DiscussionEntry.last
    refresh_page

    expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy, "precondition"
    edit_entry(entry, edit_text)
    expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy
  end

  it "should display editor name and timestamp after delete", priority: "2", test_id: 222525  do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    fj('label[for="showDeleted"]').click()
    add_reply(entry_text)
    entry = DiscussionEntry.last
    delete_entry(entry)
    expect(f("#entry-#{entry.id} .discussion-title").text).to match("Deleted by #{@teacher.name} on")
  end
end
