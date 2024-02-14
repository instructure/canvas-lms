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
#

require_relative "messages_helper"

describe "new_announcement" do
  include MessagesCommon

  before :once do
    course_with_teacher(active_course: true, active_enrollment: true)
    course_with_student(course: @course, active_enrollment: true)

    @a = @course.announcements.create!(
      title: "new announcement",
      message: "In the cafe!",
      user: @teacher
    )
  end

  let(:notification_name) { :new_announcement }
  let(:asset) { @a }

  context ".email" do
    let(:path_type) { :email }

    it "renders for course" do
      generate_message(notification_name, path_type, asset, user: @student)

      expect(@message.subject).to eq "#{asset.title}: #{@course.name}"
      expect(@message.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.body).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.html_body).to include "Replies to this email will be posted as a reply to the announcement, which will be seen by everyone in the course."
    end

    it "does not show reply helper if the user does not have a reply permissions" do
      @course.root_account.role_overrides.create!(permission: "post_to_forum", role: student_role, enabled: false)
      generate_message(notification_name, path_type, asset, user: @student)

      expect(@message.subject).to eq "#{asset.title}: #{@course.name}"
      expect(@message.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.body).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.html_body).not_to include "Replies to this email will be posted as a reply to the announcement, which will be seen by everyone in the course."
    end

    it "does not show announcement reply helper if announcement is locked" do
      @a.locked = true
      @a.save!

      generate_message(notification_name, path_type, asset, user: @student)
      expect(@message.subject).to eq "#{asset.title}: #{@course.name}"
      expect(@message.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.body).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.html_body).not_to include "Replies to this email will be posted as a reply to the announcement, which will be seen by everyone in the course."
    end

    it "renders for group" do
      @course.group_categories.create!(name: "My Group Category")
      teacher_in_course
      group = @course.groups.create!(name: "My Group", group_category: @course.group_categories.first)
      group_announcement = group.announcements.create!(
        title: "Group Announcement",
        message: "Group",
        user: @teacher
      )
      generate_message(notification_name, path_type, group_announcement, user: @teacher)
      expect(@message.subject).to eq "Group Announcement: My Group"
      expect(@message.url).to match(%r{/groups/\d+/announcements/\d+})
      expect(@message.body).to match(%r{/groups/\d+/announcements/\d+})
      expect(@message.html_body).to include "Replies to this email will be posted as a reply to the announcement, which will be seen by everyone in the group."
    end
  end

  context ".sms" do
    let(:path_type) { :sms }

    it "renders" do
      generate_message(notification_name, path_type, asset)
    end
  end

  context ".summary" do
    let(:path_type) { :summary }

    it "renders" do
      generate_message(notification_name, path_type, asset)
      expect(@message.subject).to eq "#{asset.title}: #{@course.name}"
      expect(@message.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.body.strip).to eq asset.message
    end
  end

  context ".twitter" do
    let(:path_type) { :twitter }

    it "renders" do
      generate_message(notification_name, path_type, asset)
      expect(@message.subject).to eq "Canvas Alert"
      expect(@message.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(@message.body).to include("Canvas Alert - Announcement: #{asset.title}")
    end
  end
end
