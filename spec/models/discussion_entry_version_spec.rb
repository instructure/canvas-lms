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
#

require_relative "../spec_helper"

describe DiscussionEntryVersion do
  describe "#message_intro" do
    let(:user) { user_model }
    let(:course) { course_model }
    let(:topic) { course.discussion_topics.create!(title: "Test Topic", message: "Test message") }
    let(:entry) { topic.discussion_entries.create!(user:, message: "Initial message") }
    let(:version) { entry.discussion_entry_versions.first }

    it "strips HTML tags from message" do
      version.update!(message: "<p>Hello <strong>world</strong></p>")
      expect(version.message_intro).to eq("Hello world")
    end

    it "truncates message at 300 characters" do
      long_message = "a" * 400
      version.update!(message: long_message)
      expect(version.message_intro.length).to eq(301) # 0..300 inclusive
      expect(version.message_intro).to eq("a" * 301)
    end

    it "returns full message when shorter than 300 characters" do
      short_message = "This is a short message"
      version.update!(message: short_message)
      expect(version.message_intro).to eq(short_message)
    end

    it "strips HTML tags before truncating" do
      # Create a message with HTML that would be >300 chars with tags but <300 without
      content = "a" * 250
      version.update!(message: "<p>#{content}</p><strong>more text here</strong>")
      result = version.message_intro
      expect(result).not_to include("<p>")
      expect(result).not_to include("</p>")
      expect(result).not_to include("<strong>")
      expect(result.length).to be <= 301
    end

    it "handles message with nested HTML tags" do
      version.update!(message: "<div><p>Hello <em>beautiful</em> <strong>world</strong></p></div>")
      expect(version.message_intro).to eq("Hello beautiful world")
    end

    it "handles empty message" do
      version.update!(message: "")
      expect(version.message_intro).to eq("")
    end

    it "truncates at exactly MESSAGE_INTRO_TRUNCATE_LENGTH" do
      expect(DiscussionEntryVersion::MESSAGE_INTRO_TRUNCATE_LENGTH).to eq(300)
      message = "x" * 500
      version.update!(message:)
      # 0..300 means 301 characters (indices 0 through 300 inclusive)
      expect(version.message_intro.length).to eq(301)
      expect(version.message_intro).to eq("x" * 301)
    end
  end
end
