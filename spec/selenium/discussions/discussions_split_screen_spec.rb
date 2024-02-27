# frozen_string_literal: true

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

require_relative "../helpers/discussions_common"
require_relative "pages/discussion_page"

describe "threaded discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before :once do
    course_with_teacher(active_course: true, active_all: true, name: "teacher")
    @topic_title = "threaded discussion topic"
    @topic = create_discussion(@topic_title, "threaded")
    @student = student_in_course(course: @course, name: "student", active_all: true).user
  end

  before do
    stub_rcs_config
    Account.site_admin.enable_feature! :react_discussions_post

    @first_reply = @topic.discussion_entries.create!(
      user: @student,
      message: "1st level reply"
    )
    @second_reply = DiscussionEntry.create!(
      message: "2nd level reply",
      discussion_topic_id: @first_reply.discussion_topic_id,
      user_id: @first_reply.user_id,
      root_entry_id: @first_reply.id,
      parent_id: @first_reply.id
    )

    @deleted_reply = DiscussionEntry.create!(
      message: "1.2 reply",
      discussion_topic_id: @first_reply.discussion_topic_id,
      user_id: @first_reply.user_id,
      root_entry_id: @first_reply.id,
      parent_id: @first_reply.id
    )
    @deleted_reply.destroy
  end

  it "toggles from inline to split-screen" do
    # initially set user preference discussions_split_screen, so 'Inline will be the initial View'
    @teacher.preferences[:discussions_splitscreen_view] = false
    @teacher.save!

    user_session(@teacher)
    Discussion.visit(@course, @topic)

    f("button[data-testid='expand-button']").click
    wait_for_ajaximations

    # Check for inline, no split screen
    expect(fj("div:contains('2nd level reply')")).to be_truthy
    expect(f("body")).not_to contain_jqcss("div[data-testid='drawer-layout-tray']")

    # click ss button
    f("button[data-testid='splitscreenButton']").click
    wait_for_ajaximations

    # check inline closes
    expect(f("body")).not_to contain_jqcss("div:contains('2nd level reply')")

    f("button[data-testid='expand-button']").click
    wait_for_ajaximations

    # Check for split screen
    expect(fj("div:contains('2nd level reply')")).to be_truthy
    expect(f("div[data-testid='drawer-layout-tray']")).to be_truthy

    f("button[data-testid='splitscreenButton']").click
    wait_for_ajaximations

    # check ss closes
    expect(f("body")).not_to contain_jqcss("div[data-testid='drawer-layout-tray']")
  end

  it "toggles from split-screen to inline" do
    # initially set user preference discussions_split_screen, so 'Split-screen will be the initial View'
    @teacher.preferences[:discussions_splitscreen_view] = true
    @teacher.save!

    user_session(@teacher)
    Discussion.visit(@course, @topic)

    # Open split-screen
    f("button[data-testid='expand-button']").click
    wait_for_ajaximations

    # Check that split-screen is open
    expect(fj("div:contains('2nd level reply')")).to be_truthy
    expect(f("div[data-testid='drawer-layout-tray']")).to be_truthy

    # click "View Inline" button. closes the split-screen view
    f("button[data-testid='splitscreenButton']").click
    wait_for_ajaximations

    f("button[data-testid='expand-button']").click
    wait_for_ajaximations

    # Check that inline view is open
    expect(fj("div:contains('2nd level reply')")).to be_truthy
    expect(f("body")).not_to contain_jqcss("div[data-testid='drawer-layout-tray']")
  end

  it "auto reads inline entries" do
    # initially set user preference discussions_split_screen, so 'Inline will be the initial View'
    @teacher.preferences[:discussions_splitscreen_view] = false
    @teacher.save!
    user_session(@teacher)
    expect(@first_reply.discussion_entry_participants.where(user: @teacher).count).to eq 0
    expect(@second_reply.discussion_entry_participants.where(user: @teacher).count).to eq 0
    Discussion.visit(@course, @topic)
    wait_for_ajaximations
    expect(f("div[data-testid='replies-counter']")).to include_text("2 Replies, 2 Unread")
    expect(f("div[data-testid='is-unread']")).to be_displayed
    f("button[data-testid='expand-button']").click
    wait_for_ajaximations
    # Auto read has a 3 second delay before firing off the read event
    keep_trying_until { @first_reply.discussion_entry_participants.where(user: @teacher).first.workflow_state == "read" }
    wait_for_ajaximations
    expect(@first_reply.discussion_entry_participants.where(user: @teacher).first.workflow_state).to eq "read"
    expect(@second_reply.discussion_entry_participants.where(user: @teacher).first.workflow_state).to eq "read"
    expect(f("div[data-testid='replies-counter']")).to include_text("2 Replies")
    expect(f("div[data-testid='replies-counter']")).not_to include_text("2 Replies, 2 Unread")
    wait_for_ajaximations
    expect(f("body")).not_to contain_jqcss("div[data-testid='is-unread']")
  end

  it "auto reads splitscreen entries" do
    # initially set user preference discussions_split_screen, so 'Inline will be the initial View'
    @teacher.preferences[:discussions_splitscreen_view] = true
    @teacher.save!
    user_session(@teacher)
    expect(@first_reply.discussion_entry_participants.where(user: @teacher).count).to eq 0
    expect(@second_reply.discussion_entry_participants.where(user: @teacher).count).to eq 0
    Discussion.visit(@course, @topic)
    wait_for_ajaximations
    expect(f("div[data-testid='replies-counter']")).to include_text("2 Replies, 2 Unread")
    expect(f("div[data-testid='is-unread']")).to be_displayed
    f("button[data-testid='expand-button']").click
    wait_for_ajaximations
    wait_for_ajax_requests
    # Auto read has a 3 second delay before firing off the read event
    wait_for(method: nil, timeout: 1) { expect(f("div[data-testid='threading-toolbar-reply']")).to include_text("Reply") }
    wait_for(method: nil, timeout: 3) { keep_trying_until { @first_reply.discussion_entry_participants.where(user: @teacher).first&.workflow_state == "read" } }
    wait_for_ajaximations
    expect(@first_reply.discussion_entry_participants.where(user: @teacher).first&.workflow_state).to eq "read"
    expect(@second_reply.discussion_entry_participants.where(user: @teacher).first&.workflow_state).to eq "read"
    expect(f("div[data-testid='replies-counter']")).to include_text("2 Replies")
    expect(f("div[data-testid='replies-counter']")).not_to include_text("2 Replies, 2 Unread")
    wait_for_ajaximations
    expect(f("body")).not_to contain_jqcss("div[data-testid='is-unread']")
  end

  it "allows you to click the mobile RCE without closing", :ignore_js_errors do
    driver.manage.window.resize_to(565, 836)

    # initially set user preference discussions_split_screen, so 'split-screen will be the initial View'
    @teacher.preferences[:discussions_splitscreen_view] = true
    @teacher.save!

    user_session(@teacher)
    Discussion.visit(@course, @topic)

    f("button[data-testid='threading-toolbar-reply']").click
    wait_for_ajaximations
    f(".tox-edit-area__iframe").click

    wait_for_ajaximations
    expect(f("span[data-testid='discussions-split-screen-view-content']")).to be_truthy
  end
end
