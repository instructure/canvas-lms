# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
require_relative "../common"

describe "Discussion Topic Navigation Shortcuts" do
  include_context "in-process server selenium tests"

  context "when Discussion Replies are in 'Inline' mode" do
    before :once do
      Account.default.enable_feature!(:react_discussions_post)

      # It should work without these flags
      # But this makes the tasting easier
      Account.site_admin.enable_feature!(:discussion_default_expand)
      Account.site_admin.enable_feature!(:discussion_default_sort)
    end

    before :once do
      course_with_teacher(active_course: true, active_all: true, name: "teacher")
      @topic_title = "Our Discussion Topic"
      @topic = @course.discussion_topics.create!(
        title: @topic_title,
        message: "topic message",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        sort_order: "asc",
        expanded: true,
        expanded_locked: true
      )
      @topic.save!
    end

    before do
      @topic.discussion_entries.destroy_all
      @topic.expanded_locked = true
      @topic.expanded = true
      @topic.save!
    end

    it "does have root level replies and it can be navigated" do
      (1..5).each do |number|
        @topic.discussion_entries.create!(
          user: @teacher,
          message: "foo #{number}"
        )
      end
      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      # Simulate two key press events with the "j" character
      2.times { driver.action.send_keys("j").perform }

      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include("foo 2")

      # Moves to the other direction
      driver.action.send_keys("k").perform
      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include("foo 1")

      # Doesn't rotate
      driver.action.send_keys("k").perform
      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include("foo 1")

      # Doesn't rotate at the end either
      6.times { driver.action.send_keys("j").perform }
      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include("foo 5")
    end

    it "does have sub level replies and it can be navigated" do
      sub_entry_id = nil
      (1..5).each do |number|
        entry = @topic.discussion_entries.create!(
          user: @teacher,
          message: "root #{number}"
        )

        next if number != 2

        (1..5).each do |sub_number|
          sub_entry = entry.reply_from(
            user: @teacher,
            text: "sub #{number}-#{sub_number}"
          )

          sub_entry_id = sub_entry.id if sub_number == 2
        end
      end

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

      # wait until the sub entries are loaded
      f("[data-entry-id='#{sub_entry_id}']")
      4.times { driver.action.send_keys("j").perform }

      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include("sub 2-2")

      4.times { driver.action.send_keys("j").perform }
      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include("root 3")
    end

    it "does skip a deleted entry if no sub entries there otherwise it doesn't" do
      @topic.expanded_locked = false
      @topic.expanded = false
      @topic.save!

      participant = @topic.discussion_topic_participants.where(user: @teacher).first
      participant.expanded = false
      participant.save!

      sub_entry_id = nil
      (1..5).each do |number|
        entry = @topic.discussion_entries.create!(
          user: @teacher,
          message: "root #{number}"
        )

        if number == 2
          (1..5).each do |sub_number|
            sub_entry = entry.reply_from(user: @teacher, text: "sub #{number}-#{sub_number}")
            sub_entry_id = sub_entry.id if sub_number == 2
          end
        end
        entry.destroy if [2, 3].include?(number)
      end

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

      2.times { driver.action.send_keys("j").perform }

      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include(/Deleted/i)

      driver.action.send_keys("j").perform
      focused_element = driver.switch_to.active_element
      expect(focused_element.text).to include("root 4")
    end
  end
end
