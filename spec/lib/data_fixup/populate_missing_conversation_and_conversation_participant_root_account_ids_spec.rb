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
#

describe DataFixup::PopulateMissingConversationAndConversationParticipantRootAccountIds do
  let(:account) { account_model }

  describe(".run") do
    before do
      @user_1 = User.create(root_account_ids: [account.root_account_id])
      @user_2 = User.create(root_account_ids: [account.root_account_id])

      @course = Course.create
    end

    describe "Conversation" do
      it "updates the root_account_ids when nil" do
        convo = Conversation.initiate(
          [@user_1, @user_2],
          false,
          {
            subject: "From #{@user_1.id}",
            context_type: "Course",
            context_id: @course.id
          }
        )
        convo.add_message(@user_1, "The quick brown fox jumps over the lazy dog")

        convo.root_account_ids = nil
        convo.save!

        cp = convo.conversation_participants.first
        cp.root_account_ids = nil
        cp.save!

        expect do
          DataFixup::PopulateMissingConversationAndConversationParticipantRootAccountIds.run
        end.to change { convo.reload.root_account_ids }.from([]).to([@user_1.root_account_ids, @user_2.root_account_ids].flatten.uniq.sort)
      end

      it "updates the root_account_ids when \"\"" do
        convo = Conversation.initiate(
          [@user_1, @user_2],
          false,
          {
            subject: "From #{@user_1.id}",
            context_type: "Course",
            context_id: @course.id
          }
        )
        convo.add_message(@user_1, "The quick brown fox jumps over the lazy dog")

        convo.root_account_ids = ""
        convo.save!

        cp = convo.conversation_participants.first
        cp.root_account_ids = ""
        cp.save!

        expect(cp.root_account_ids).to match([])

        expect do
          DataFixup::PopulateMissingConversationAndConversationParticipantRootAccountIds.run
        end.to change { convo.reload.root_account_ids }.from([]).to([@user_1.root_account_ids, @user_2.root_account_ids].flatten.uniq.sort)
      end
    end

    describe "ConversationParticipant" do
      it "updates the root_account_ids when nil" do
        convo = Conversation.initiate(
          [@user_1, @user_2],
          false,
          {
            subject: "From #{@user_1.id}",
            context_type: "Course",
            context_id: @course.id
          }
        )
        convo.add_message(@user_1, "The quick brown fox jumps over the lazy dog")

        convo.root_account_ids = nil
        convo.save!

        cp = convo.conversation_participants.first
        cp.root_account_ids = nil
        cp.save!

        expect(cp.root_account_ids).to match([])

        expect do
          DataFixup::PopulateMissingConversationAndConversationParticipantRootAccountIds.run
        end.to change { cp.reload.root_account_ids }.from([]).to([@user_1.root_account_ids, @user_2.root_account_ids].flatten.uniq.sort)
      end

      it "updates the root_account_ids when \"\"" do
        convo = Conversation.initiate(
          [@user_1, @user_2],
          false,
          {
            subject: "From #{@user_1.id}",
            context_type: "Course",
            context_id: @course.id
          }
        )
        convo.add_message(@user_1, "The quick brown fox jumps over the lazy dog")

        convo.root_account_ids = ""
        convo.save!

        cp = convo.conversation_participants.first
        cp.root_account_ids = ""
        cp.save!

        expect(cp.root_account_ids).to match([])

        expect do
          DataFixup::PopulateMissingConversationAndConversationParticipantRootAccountIds.run
        end.to change { cp.reload.root_account_ids }.from([]).to([@user_1.root_account_ids, @user_2.root_account_ids].flatten.uniq.sort)
      end
    end
  end
end
