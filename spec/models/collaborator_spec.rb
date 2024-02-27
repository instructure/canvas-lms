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
#

describe Collaborator do
  before :once do
    course_with_teacher(active_all: true)
    @notification       = Notification.create!(name: "Collaboration Invitation")
    @author             = @teacher
    @collaboration      = Collaboration.new(title: "Test collaboration")
    @collaboration.context = @course
    @collaboration.type = "EtherpadCollaboration"
    @collaboration.user = @author
  end

  context "broadcast policy" do
    it "notifies collaborating users", priority: "1" do
      user = user_with_pseudonym(active_all: true)
      @course.enroll_student(user, enrollment_state: "active")
      @collaboration.update_members([user])
      expect(@collaboration.collaborators.detect { |c| c.user_id == user.id }
        .messages_sent.keys).to eq ["Collaboration Invitation"]
    end

    it "does not notify the author" do
      NotificationPolicy.create(notification: @notification,
                                communication_channel: @author.communication_channel,
                                frequency: "immediately")
      @collaboration.update_members([@author])
      expect(@collaboration.reload.collaborators.detect { |c| c.user_id == @author.id }
        .messages_sent.keys).to be_empty
    end

    it "notifies all members of a group" do
      group = group_model(name: "Test group", context: @course)
      users = (1..2).map { user_with_pseudonym(active_all: true) }
      users.each do |u|
        @course.enroll_student(u, enrollment_state: "active")
        group.add_user(u, "active")
      end
      @collaboration.update_members([], [group.id])
      expect(@collaboration.collaborators.detect { |c| c.group_id.present? }
        .messages_sent.keys).to include "Collaboration Invitation"
    end

    it "does not notify members of a group that have not accepted the course enrollemnt" do
      group = group_model(name: "Test group", context: @course)
      user = user_with_pseudonym(active_all: true)
      @course.enroll_student(user)
      group.add_user(user, "active")
      @collaboration.update_members([], [group.id])
      expect(@collaboration.collaborators.detect { |c| c.group_id.present? }
        .messages_sent.keys).to be_empty
    end

    it "does not notify members of a group in an unpublished course" do
      group = group_model(name: "Test group", context: @course)
      user = user_with_pseudonym(active_all: true)
      @course.enroll_student(user)
      user.enrollments.first.accept!
      @course.update_attribute(:workflow_state, "claimed")
      group.add_user(user, "active")
      @collaboration.update_members([], [group.id])
      expect(@collaboration.collaborators.detect { |c| c.group_id.present? }
        .messages_sent.keys).to be_empty
    end
  end
end
