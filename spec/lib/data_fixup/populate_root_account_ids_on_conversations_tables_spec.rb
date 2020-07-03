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

require 'spec_helper'

describe DataFixup::PopulateRootAccountIdsOnConversationsTables do

  def ids_to_string(*ids)
    ids.sort.join(',')
  end

  def reset_root_account_ids(*models)
    models.each { |m| m.update_column(:root_account_ids, nil) }
  end

  def check_root_account_ids(expected, *models)
    models.each { |m| expect(m.reload.root_account_ids).to eq expected}
  end

  before :once do
    @root_account1 = account_model
    @root_account2 = account_model
    @user1 = user_model
    @user2 = user_model
  end

  def check_conversation_messages(conversation, ids)
    cm1 = ConversationMessage.create!(conversation: conversation)
    cm2 = ConversationMessage.create!(conversation: conversation)
    reset_root_account_ids(cm1, cm2)
    DataFixup::PopulateRootAccountIdsOnConversationsTables.run(conversation.id, conversation.id)
    check_root_account_ids(ids, cm1, cm2)
  end

  def check_conversation_participants(conversation, ids)
    cp1 = ConversationParticipant.create!(conversation: conversation, user: @user1)
    cp2 = ConversationParticipant.create!(conversation: conversation, user: @user2)
    reset_root_account_ids(cp1, cp2)
    DataFixup::PopulateRootAccountIdsOnConversationsTables.run(conversation.id, conversation.id)
    check_root_account_ids(ids, cp1, cp2)
  end

  def check_conversation_message_participants(conversation, ids)
    cm1 = ConversationMessage.create!(conversation: conversation)
    cm2 = ConversationMessage.create!(conversation: conversation)
    cmp1 = ConversationMessageParticipant.create!(conversation_message: cm1, user: @user1)
    cmp2 = ConversationMessageParticipant.create!(conversation_message: cm2, user: @user2)
    reset_root_account_ids(cm1, cm2, cmp1, cmp2)
    DataFixup::PopulateRootAccountIdsOnConversationsTables.run(conversation.id, conversation.id)
    check_root_account_ids(ids, cmp1, cmp2)
  end

  context 'single-account Conversation' do
    before :once do
      @ids = [@root_account1.id]
      @c = Conversation.create!(root_account_ids: ids_to_string(@root_account1.id))
    end

    it 'sets root account id on all associated ConversationMessages' do
      check_conversation_messages(@c, @ids)
    end

    it 'sets root account id on all associated ConversationParticipants' do
      check_conversation_participants(@c, @ids)
    end

    it 'sets root account id on all ConversationMessageParticipants through ConversationMessage' do
      check_conversation_message_participants(@c, @ids)
    end
  end

  context 'multiple-account Conversation' do
    before :once do
      @ids = [@root_account1.id, @root_account2.id]
      @c = Conversation.create!(root_account_ids: ids_to_string(@root_account1.id, @root_account2.id))
    end

    it 'sets root account ids on all associated ConversationMessages' do
      check_conversation_messages(@c, @ids)
    end

    it 'sets root account ids on all associated ConversationParticipants' do
      check_conversation_participants(@c, @ids)
    end

    it 'sets root account ids on all ConversationMessageParticipants through ConversationMessage' do
      check_conversation_message_participants(@c, @ids)
    end
  end

  context 'cross-shard Conversation' do
    specs_require_sharding

    before :once do
      cross_shard_account = @shard1.activate do
        account_model
      end

      @ids = [@root_account1.id, cross_shard_account.id]
      @c = Conversation.create!(root_account_ids: ids_to_string(@root_account1.id, cross_shard_account.id))
    end

    it 'sets root account ids on all associated ConversationMessages' do
      check_conversation_messages(@c, @ids)
    end

    it 'sets root account ids on all associated ConversationParticipants' do
      check_conversation_participants(@c, @ids)
    end

    it 'sets root account ids on all ConversationMessageParticipants through ConversationMessage' do
      check_conversation_message_participants(@c, @ids)
    end
  end

end