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
#

require_relative "../graphql_spec_helper"

describe Types::ConversationType do
  before(:once) do
    student_in_course(active_all: true)
    @student2 = @student
    student_in_course(active_all: true)
    @student.update!(name: "Morty Smith")
    @teacher.update!(name: "Rick Sanchez")
    conversation(@student, @teacher, { body: "You sold a gun to a murderer so you could play video games?" })
    @media_object = media_object(user: @teacher)
    @attachment = @teacher.conversation_attachments_folder.attachments.create!(
      context: @teacher,
      filename: "blips_and_chitz.txt",
      display_name: "blips_and_chitz.txt",
      uploaded_data: StringIO.new("test")
    )
    @conversation.conversation.add_message(
      @teacher,
      "Yea, sure, I mean, if you spend all day shuffling words around, you can make anything sound bad, Morty.",
      {
        attachment_ids: [@attachment.id],
        media_comment: media_object
      }
    )
    @student_conversation = Conversation.initiate([@student2, @student], false, context_type: "Course", context_id: @course.id)
  end

  let(:conversation_type) { GraphQLTypeTester.new(@conversation.conversation, current_user: @teacher) }

  context "conversation can_reply permission" do
    let(:conversation_students_type) { GraphQLTypeTester.new(@student_conversation, current_user: @student2) }

    context "student message permission is off" do
      before do
        @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)
        @course.account.role_overrides.create!(permission: :send_messages_all, role: student_role, enabled: false)
      end

      it "returns false when conversation is between students" do
        result = conversation_students_type.resolve("canReply")
        expect(result).to eq(false)
      end

      it "returns true when conversation is between teacher and student" do
        result = conversation_type.resolve("canReply")
        expect(result).to eq(true)
      end
    end

    context "student message permission is on" do
      before do
        @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: true)
        @course.account.role_overrides.create!(permission: :send_messages_all, role: student_role, enabled: true)
      end

      it "returns true when conversation is between students" do
        result = conversation_students_type.resolve("canReply")
        expect(result).to eq(true)
      end

      it "returns true when conversation is between teacher and student" do
        result = conversation_type.resolve("canReply")
        expect(result).to eq(true)
      end
    end
  end

  context "conversationMessages" do
    it "returns conversation messages" do
      result = conversation_type.resolve("conversationMessagesConnection { nodes { body } }")
      expect(result).to include(@conversation.conversation.conversation_messages[0].body)
      expect(result).to include(@conversation.conversation.conversation_messages[1].body)
    end

    it "returns the message author" do
      result = conversation_type.resolve("conversationMessagesConnection { nodes { author { name } } }")
      expect(result).to include(@teacher.name)
      expect(result).to include(@student.name)
    end

    it "returns attachments" do
      result = conversation_type.resolve("conversationMessagesConnection { nodes { attachmentsConnection { nodes { displayName } } } }")
      expect(result[0][0]).to eq(@attachment.display_name)
    end

    it "returns media comments" do
      result = conversation_type.resolve("conversationMessagesConnection { nodes { mediaComment { title } } }")
      expect(result[0]).to eq(@media_object.title)
    end

    it "returns conversations for the given participants" do
      result = conversation_type.resolve("conversationMessagesConnection(participants: [#{@student.id}, #{@teacher.id}]) { nodes { body } }")
      expect(result).to include(@conversation.conversation.conversation_messages[0].body)
      expect(result).to include(@conversation.conversation.conversation_messages[1].body)

      result = conversation_type.resolve("conversationMessagesConnection(participants: [#{@student.id + 1337}]) { nodes { body } }")
      expect(result).to be_empty
    end

    it "returns conversation messages before a given date" do
      @conversation.conversation.conversation_messages[0].update!(created_at: Time.zone.now - 5.days)
      result = conversation_type.resolve(%|conversationMessagesConnection(createdBefore: "#{(Time.zone.now - 1.day).iso8601}") { nodes { body } }|)
      expect(result).to include(@conversation.conversation.conversation_messages[0].body)
      expect(result).not_to include(@conversation.conversation.conversation_messages[1].body)
    end

    it "ignores nanoseconds when comparing time" do
      float_time = (Time.zone.now - 1.day).to_f.floor
      @conversation.conversation.conversation_messages[0].update!(created_at: Time.zone.at(float_time + 0.5))
      result = conversation_type.resolve(%|conversationMessagesConnection(createdBefore: "#{Time.zone.at(float_time).iso8601}") { nodes { body } }|)
      expect(result).to include(@conversation.conversation.conversation_messages[0].body)
    end

    it "does not return deleted messages" do
      message = @conversation.conversation.add_message(@student, "delete me")
      message.conversation_message_participants.where(user_id: @teacher.id).first.update!(workflow_state: "deleted")
      result = conversation_type.resolve("conversationMessagesConnection { nodes { body } }")
      expect(result).to match_array(@conversation.conversation.conversation_messages.where.not(id: message).pluck(:body))
    end
  end

  context "conversationPaticipants" do
    it "returns the conversation participants" do
      result = conversation_type.resolve("conversationParticipantsConnection { nodes { user { name } } }")
      expect(result).to include(@teacher.name)
      expect(result).to include(@student.name)
    end
  end
end
