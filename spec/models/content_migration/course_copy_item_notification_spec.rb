# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "course_copy_helper"

describe ContentMigration do
  context "send_item_notifications" do
    include_context "course copy"

    before :once do
      @copy_from.assignments.create!(name: "assignment", description: "foo")
      @copy_from.announcements.create!(title: "announcement", message: "bar")
      @copy_from.discussion_topics.create!(title: "discussion", message: "baz")
      @copy_from.calendar_events.create!(title: "event", description: "splat", start_at: 1.day.from_now)

      Notification.create!(name: "Assignment Created", category: "TestImmediately")
      Notification.create!(name: "New Announcement", category: "TestImmediately")
      Notification.create!(name: "New Discussion Topic", category: "TestImmediately")
      Notification.create!(name: "New Event Created", category: "TestImmediately")

      student_in_course(course: @copy_to, active_all: true)
      communication_channel(@student, active_all: true)
      @copy_to.offer!
    end

    it "doesn't notify about item creation by default" do
      run_course_copy

      expect(@student.messages).to be_empty
    end

    it "notifies about item creation if the send_item_notifications setting is given" do
      @cm.migration_settings[:send_item_notifications] = true
      @cm.save!

      run_course_copy

      expect(@student.messages.pluck(:notification_name)).to match_array(["New Announcement",
                                                                          "New Discussion Topic",
                                                                          "Assignment Created",
                                                                          "New Event Created"])
    end
  end
end
