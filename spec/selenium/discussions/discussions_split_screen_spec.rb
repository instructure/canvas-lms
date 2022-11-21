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
  end

  it "toggles splitscreen" do
    Account.site_admin.enable_feature! :react_discussions_post
    Account.site_admin.enable_feature! :split_screen_view

    # initially set user preference discussions_split_screen, so 'Inline will be the initial View'
    @teacher.preferences[:discussions_splitscreen_view] = false
    @teacher.save!

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
end
