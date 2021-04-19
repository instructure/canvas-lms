# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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


require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe DiscussionTopicParticipant do
  describe 'check_unread_count' do
    before(:once) do
      @participant = DiscussionTopicParticipant.create!(:user => user_factory,
        :discussion_topic => discussion_topic_model)
    end

    it 'should set negative unread_counts to zero on save' do
      @participant.update_attribute(:unread_entry_count, -15)
      expect(@participant.unread_entry_count).to eq 0
    end

    it 'should not change an unread_count of zero' do
      @participant.update_attribute(:unread_entry_count, 0)
      expect(@participant.unread_entry_count).to eq 0
    end

    it 'should not change a positive unread_count' do
      @participant.update_attribute(:unread_entry_count, 15)
      expect(@participant.unread_entry_count).to eq 15
    end
  end

  describe 'create' do
    before(:once) do
      @participant = DiscussionTopicParticipant.create!(:user => user_factory,
        :discussion_topic => discussion_topic_model)
    end

    it 'sets the root_account_id using topic' do
      expect(@participant.root_account_id).to eq @topic.root_account_id
    end
  end
end
