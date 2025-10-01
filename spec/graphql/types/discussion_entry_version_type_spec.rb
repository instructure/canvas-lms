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

require_relative "../graphql_spec_helper"

describe Types::DiscussionEntryVersionType do
  before(:once) do
    course_with_teacher(active_all: true)
    @topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test", user: @teacher)
    @entry = @topic.discussion_entries.create!(message: "Hello!", user: @teacher, editor: @teacher)
  end

  let(:discussion_entry_type) { GraphQLTypeTester.new(@entry, current_user: @teacher) }

  describe "HTML stripping" do
    it "strips HTML tags from the messageIntro" do
      @entry.message = "<p>This is a <strong>bold</strong> message with <em>emphasis</em></p>"
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      # Versions are returned in reverse order (newest first)
      expect(messages.first).to eq "This is a bold message with emphasis"
      expect(messages.first).not_to include("<p>")
      expect(messages.first).not_to include("<strong>")
      expect(messages.first).not_to include("<em>")
      expect(messages.first).not_to include("</p>")
    end

    it "strips complex HTML including links" do
      @entry.message = '<p>Check out <a href="https://example.com">this link</a> for more info</p>'
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      expect(messages.first).to eq "Check out this link for more info"
      expect(messages.first).not_to include("<a")
      expect(messages.first).not_to include("href")
    end

    it "strips HTML with nested tags" do
      @entry.message = "<div><p>Outer <span>inner <strong>bold</strong> text</span> content</p></div>"
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      expect(messages.first).to eq "Outer inner bold text content"
    end

    it "handles messages with only HTML tags" do
      @entry.message = "<br/><br/>"
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      expect(messages.first.strip).to eq ""
    end

    it "preserves whitespace appropriately" do
      @entry.message = "<p>First paragraph</p>\n<p>Second paragraph</p>"
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      expect(messages.first).to include("First paragraph")
      expect(messages.first).to include("Second paragraph")
    end

    it "handles plain text messages without HTML" do
      @entry.message = "Plain text message"
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      expect(messages.first).to eq "Plain text message"
    end

    it "strips HTML and decodes HTML entities" do
      @entry.message = "<p>Price: $100 &amp; up</p>"
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      # HtmlTextHelper.strip_tags also decodes HTML entities
      expect(messages.first).to include("Price:")
      expect(messages.first).to include("$100")
      expect(messages.first).to include("up")
    end

    it "strips HTML from multiple versions" do
      @entry.message = "<p>Version <strong>2</strong></p>"
      @entry.save!

      @entry.message = "<p>Version <em>3</em> with <a href='#'>link</a></p>"
      @entry.save!

      messages = discussion_entry_type.resolve("discussionEntryVersions { messageIntro }")
      # Versions are returned in reverse order (newest first)
      expect(messages[0]).to eq "Version 3 with link"
      expect(messages[1]).to eq "Version 2"
      expect(messages[2]).to eq "Hello!"
    end
  end

  describe "version field" do
    it "returns the version number" do
      @entry.message = "Updated message"
      @entry.save!

      versions = discussion_entry_type.resolve("discussionEntryVersions { version }")
      expect(versions).to eq [2, 1]
    end
  end

  describe "timestamps" do
    it "returns createdAt for each version" do
      @entry.message = "Updated message"
      @entry.save!

      created_ats = discussion_entry_type.resolve("discussionEntryVersions { createdAt }")
      expect(created_ats).to be_an(Array)
      expect(created_ats.size).to eq 2
      created_ats.each do |created_at|
        expect(created_at).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end
    end

    it "returns updatedAt for each version" do
      @entry.message = "Updated message"
      @entry.save!

      updated_ats = discussion_entry_type.resolve("discussionEntryVersions { updatedAt }")
      expect(updated_ats).to be_an(Array)
      expect(updated_ats.size).to eq 2
      updated_ats.each do |updated_at|
        expect(updated_at).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end
    end
  end

  describe "legacy ID" do
    it "returns the _id for each version" do
      @entry.message = "Updated message"
      @entry.save!

      ids = discussion_entry_type.resolve("discussionEntryVersions { _id }")
      expect(ids).to be_an(Array)
      expect(ids.size).to eq 2
      ids.each do |id|
        expect(id).to match(/^\d+$/)
      end
    end
  end
end
