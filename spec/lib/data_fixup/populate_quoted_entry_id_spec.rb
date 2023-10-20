# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe DataFixup::PopulateQuotedEntry do
  describe(".run") do
    before do
      course_with_teacher(active_all: true)
      discussion_topic_model({ context: @course, discussion_type: DiscussionTopic::DiscussionTypes::THREADED })
      @root_entry = @topic.discussion_entries.create!(message: "root entry", user: @teacher, discussion_topic: @topic)
      @other_root_entry = @topic.discussion_entries.create!(message: "root entry", user: @teacher, discussion_topic: @topic)
    end

    it "ignores entries where include_reply_preview is false" do
      entry_not_quoted = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: @root_entry)

      expect(entry_not_quoted.quoted_entry_id).to be_nil
      DataFixup::PopulateQuotedEntry.run
      expect(entry_not_quoted.reload.quoted_entry_id).to be_nil
    end

    it "updates the quoted_entry_id for" do
      entry_quoted_old = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: @root_entry, include_reply_preview: true)

      expect(entry_quoted_old.quoted_entry_id).to be_nil
      DataFixup::PopulateQuotedEntry.run
      expect(entry_quoted_old.reload.quoted_entry_id).to eq @root_entry.id
    end

    it "ignores discussion entries that already have a quoted_entry_id" do
      entry_quoted_with_quoted_entry_id = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: @root_entry, quoted_entry_id: @other_root_entry)

      expect(entry_quoted_with_quoted_entry_id.quoted_entry_id).to eq @other_root_entry.id
      DataFixup::PopulateQuotedEntry.run
      expect(entry_quoted_with_quoted_entry_id.reload.quoted_entry_id).to eq @other_root_entry.id
    end

    it "ignores discussion entries that have no parent_id" do
      entry_quoted_with_no_parent_id = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: nil, include_reply_preview: true)

      expect(entry_quoted_with_no_parent_id.quoted_entry_id).to be_nil
      DataFixup::PopulateQuotedEntry.run
      expect(entry_quoted_with_no_parent_id.quoted_entry_id).to be_nil
    end
  end
end
