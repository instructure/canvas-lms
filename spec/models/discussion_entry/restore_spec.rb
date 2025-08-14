# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

describe "Restore Discussion Entry" do
  before :once do
    @course = Course.create!(name: "Test Course")
    course_with_teacher(active_all: true)
  end

  it "restores a basic discussion entry" do
    discussion_topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message")
    discussion_entry = discussion_topic.discussion_entries.create!(message: "Test Entry", user: @teacher)
    discussion_entry.destroy
    discussion_entry.reload
    expect(discussion_entry.workflow_state).to eq("deleted")
    expect(discussion_entry.deleted_at).not_to be_nil

    discussion_entry.restore
    discussion_entry.reload

    expect(discussion_entry).not_to be_nil
    expect(discussion_entry.deleted_at).to be_nil
    expect(discussion_entry.workflow_state).to eq("active")
  end

  it "restores a discussion entry end show the correct unread count" do
    user = User.create!(name: "Test Student")
    @course.enroll_student(user)
    discussion_topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test Message")
    discussion_topic.discussion_entries.create!(message: "Teacher Entry", user: @teacher)
    discussion_topic.discussion_entries.create!(message: "Helper Entry", user:)
    discussion_entry = discussion_topic.discussion_entries.create!(message: "Test Entry", user:)

    participant = discussion_topic.discussion_topic_participants.where(user_id: @teacher.id).first

    expect(participant.unread_entry_count).to eq(2)

    discussion_entry.destroy
    participant.reload
    expect(participant.unread_entry_count).to eq(1)

    discussion_entry.restore
    participant.reload
    expect(participant.unread_entry_count).to eq(2)
  end
end
