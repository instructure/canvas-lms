# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe DiscussionEntryParticipant do
  describe "create" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @topic = @course.discussion_topics.create(title: "some topic")
      @entry = @topic.discussion_entries.create(message: "some message", user: @student)
      @participant = @entry.find_existing_participant(@student)
    end

    it "sets the root account id from the discussion_topic_entry" do
      expect(@participant.root_account_id).to eq(@entry.root_account_id)
    end

    it "throws error on regular create" do
      user = user_model
      expect { @entry.discussion_entry_participants.create!(user: user, workflow_state: "read") }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "throws error on upsert_for_entries with invalid report_type" do
      user = user_model
      expect { DiscussionEntryParticipant.upsert_for_entries(@entry, user, report_type: "wrong_type") }
        .to raise_error(ArgumentError)
    end

    describe "using upsert_for_entries with valid report_type" do
      it "when inappropriate" do
        user = user_model
        DiscussionEntryParticipant.upsert_for_entries(@entry, user, report_type: "inappropriate")
        discussion_entry_participant = DiscussionEntryParticipant.where(discussion_entry: @entry, user_id: user).take

        expect(discussion_entry_participant.report_type).to eq("inappropriate")
      end

      it "when offensive" do
        user = user_model
        DiscussionEntryParticipant.upsert_for_entries(@entry, user, report_type: "offensive")
        discussion_entry_participant = DiscussionEntryParticipant.where(discussion_entry: @entry, user_id: user).take

        expect(discussion_entry_participant.report_type).to eq("offensive")
      end

      it "when other" do
        user = user_model
        DiscussionEntryParticipant.upsert_for_entries(@entry, user, report_type: "other")
        discussion_entry_participant = DiscussionEntryParticipant.where(discussion_entry: @entry, user_id: user).take

        expect(discussion_entry_participant.report_type).to eq("other")
      end
    end

    it "returns early if there is no entry" do
      expect(DiscussionEntryParticipant.upsert_for_entries(nil, double)).to be_nil
    end

    it "returns early if there is no user" do
      expect(DiscussionEntryParticipant.upsert_for_entries(double, nil)).to be_nil
    end
  end
end
