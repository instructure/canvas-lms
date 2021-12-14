# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe Loaders::EntryParticipantLoader do
  before(:once) do
    @discussion = group_discussion_assignment
    @entry = @discussion.discussion_entries.create!(message: "peekaboo", user: @teacher, created_at: Time.zone.now)
    @entry.update_or_create_participant(new_state: "read", current_user: @teacher, forced: true, report_type: "offensive", rating: 0)
  end

  it "works" do
    GraphQL::Batch.batch do
      discussion_entry_participant_loader = Loaders::EntryParticipantLoader.for(
        current_user: @teacher
      )
      discussion_entry_participant_loader.load(@entry).then do |discussion_entry_participants|
        expect(discussion_entry_participants["rating"]).to match false
        expect(discussion_entry_participants["forced_read_state"]).to match @entry.discussion_entry_participants.first.forced_read_state
        expect(discussion_entry_participants["read"]).to match @entry.discussion_entry_participants.first.workflow_state == "read"
        expect(discussion_entry_participants["report_type"]).to match @entry.discussion_entry_participants.first.report_type
      end
    end
  end

  describe "rating" do
    context "when 0" do
      it "returns false" do
        GraphQL::Batch.batch do
          discussion_entry_participant_loader = Loaders::EntryParticipantLoader.for(
            current_user: @teacher
          )
          discussion_entry_participant_loader.load(@entry).then do |discussion_entry_participants|
            expect(discussion_entry_participants["rating"]).to match false
          end
        end
      end
    end

    context "when nil" do
      it "returns false" do
        @entry.update_or_create_participant(new_state: "read", current_user: @teacher, forced: true, report_type: "offensive", rating: nil)
        GraphQL::Batch.batch do
          discussion_entry_participant_loader = Loaders::EntryParticipantLoader.for(
            current_user: @teacher
          )
          discussion_entry_participant_loader.load(@entry).then do |discussion_entry_participants|
            expect(discussion_entry_participants["rating"]).to match false
          end
        end
      end
    end

    context "when 1" do
      it "returns true" do
        @entry.update_or_create_participant(new_state: "read", current_user: @teacher, forced: true, report_type: "offensive", rating: 1)
        GraphQL::Batch.batch do
          discussion_entry_participant_loader = Loaders::EntryParticipantLoader.for(
            current_user: @teacher
          )
          discussion_entry_participant_loader.load(@entry).then do |discussion_entry_participants|
            expect(discussion_entry_participants["rating"]).to match true
          end
        end
      end
    end
  end
end
