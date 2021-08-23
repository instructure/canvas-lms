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

require 'spec_helper'
require_relative "../graphql_spec_helper"

describe Types::ConversationType do
  before(:once) do
    student_in_course(active_all: true)
    @student.update!(name: 'Morty Smith')
    @teacher.update!(name: 'Rick Sanchez')
    conversation(@student, @teacher, {body: 'You sold a gun to a murderer so you could play video games?'})
    @media_object = media_object(user: @teacher)
    @attachment = @teacher.conversation_attachments_folder.attachments.create!(
      context: @teacher,
      filename: 'blips_and_chitz.txt',
      display_name: "blips_and_chitz.txt",
      uploaded_data: StringIO.new('test')
    )
    @conversation.conversation.add_message(
      @teacher,
      'Yea, sure, I mean, if you spend all day shuffling words around, you can make anything sound bad, Morty.',
      {
        attachment_ids: [@attachment.id],
        media_comment: media_object
      }
    )
  end

  let(:conversation_type) { GraphQLTypeTester.new(@conversation.conversation, current_user: @teacher) }

  context 'conversationMessages' do
    it 'returns conversation messages' do
      result = conversation_type.resolve('conversationMessagesConnection { nodes { body } }')
      expect(result).to include(@conversation.conversation.conversation_messages[0].body)
      expect(result).to include(@conversation.conversation.conversation_messages[1].body)
    end

    it 'returns the message author' do
      result = conversation_type.resolve('conversationMessagesConnection { nodes { author { name } } }')
      expect(result).to include(@teacher.name)
      expect(result).to include(@student.name)
    end

    it 'returns attachments' do
      result = conversation_type.resolve('conversationMessagesConnection { nodes { attachmentsConnection { nodes { displayName } } } }')
      expect(result[0][0]).to eq(@attachment.display_name)
    end

    it 'returns media comments' do
      result = conversation_type.resolve('conversationMessagesConnection { nodes { mediaComment { title } } }')
      expect(result[0]).to eq(@media_object.title)
    end

    it 'returns conversations for the given participants' do
      result = conversation_type.resolve("conversationMessagesConnection(participants: [#{@student.id}, #{@teacher.id}]) { nodes { body } }")
      expect(result).to include(@conversation.conversation.conversation_messages[0].body)
      expect(result).to include(@conversation.conversation.conversation_messages[1].body)

      result = conversation_type.resolve("conversationMessagesConnection(participants: [#{@student.id + 1337}]) { nodes { body } }")
      expect(result).to be_empty
    end
  end

  context 'conversationPaticipants' do
    it 'returns the conversation participants' do
      result = conversation_type.resolve('conversationParticipantsConnection { nodes { user { name } } }')
      expect(result).to include(@teacher.name)
      expect(result).to include(@student.name)
    end
  end
end
