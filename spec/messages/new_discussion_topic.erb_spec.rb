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

require_relative "messages_helper"

describe "new_discussion_topic" do
  before :once do
    discussion_topic_model
  end

  let(:asset) { @topic }
  let(:notification_name) { :new_discussion_topic }

  include_examples "a message"
  context "locked discussions" do
    it "sends locked notification if availibility date is locked for email" do
      @topic.update(
        unlock_at: 3.days.from_now,
        lock_at: 6.days.from_now,
        message: "the content here of the discussion body"
      )
      enrollment = course_with_student
      message = generate_message(notification_name, :email, @topic, user: enrollment.user)
      expect(message.body).to include("Discussion content is locked or not yet available")
    end

    it "sends locked notification if module is locked for email" do
      @module = @course.context_modules.create!(unlock_at: 2.days.from_now)
      @module.add_item(id: @topic.id, type: "discussion_topic")
      @topic.reload
      enrollment = course_with_student
      message = generate_message(notification_name, :email, @topic, user: enrollment.user)
      expect(message.body).to include("Discussion content is locked or not yet available")
    end

    it "sends discussion notification with discussions content when unlocked for email" do
      @topic.update(
        unlock_at: nil,
        lock_at: nil,
        message: "the content here of the discussion body"
      )
      enrollment = course_with_student
      message = generate_message(notification_name, :email, @topic, user: enrollment.user)
      expect(message.body).to include("the content here of the discussion body")
    end

    it "sends locked notification if availibility date is locked for sms" do
      @topic.update(
        unlock_at: 3.days.from_now,
        lock_at: 6.days.from_now,
        message: "the content here of the discussion body"
      )
      enrollment = course_with_student
      message = generate_message(notification_name, :sms, @topic, user: enrollment.user)
      expect(message.body).to include("Content not available")
    end

    it "sends discussion notification with discussions content when unlocked sms" do
      @topic.update(
        unlock_at: nil,
        lock_at: nil,
        message: "the content here of the discussion body"
      )
      enrollment = course_with_student
      message = generate_message(notification_name, :sms, @topic, user: enrollment.user)
      expect(message.body).to include("the content here of the discussion body")
    end

    it "sends locked notification if availibility date is locked for summary" do
      @topic.update(
        unlock_at: 3.days.from_now,
        lock_at: 6.days.from_now,
        message: "the content here of the discussion body"
      )
      enrollment = course_with_student
      message = generate_message(notification_name, :summary, @topic, user: enrollment.user)
      expect(message.body).to include("Discussion content is locked or not yet available")
    end

    it "sends discussion notification with discussions content when unlocked summary" do
      @topic.update(
        unlock_at: nil,
        lock_at: nil,
        message: "the content here of the discussion body"
      )
      enrollment = course_with_student
      message = generate_message(notification_name, :summary, @topic, user: enrollment.user)
      expect(message.body).to include("the content here of the discussion body")
    end
  end
end
