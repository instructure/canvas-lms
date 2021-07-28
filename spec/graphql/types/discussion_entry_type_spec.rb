# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative "../graphql_spec_helper"

describe Types::DiscussionEntryType do
  let_once(:discussion_entry) { create_valid_discussion_entry }
  let(:discussion_entry_type) { GraphQLTypeTester.new(discussion_entry, current_user: @teacher) }
  let(:permissions) {
    [
      {
        value: 'delete',
        allowed: proc {|user| discussion_entry.grants_right?(user, :delete)}
      },
      {
        value: 'rate',
        allowed: proc {|user| discussion_entry.grants_right?(user, :rate)}
      },
      {
        value: 'viewRating',
        allowed: proc {discussion_entry.discussion_topic.allow_rating && !discussion_entry.deleted?}
      }
    ]
  }

  it 'works' do
    expect(discussion_entry_type.resolve("_id")).to eq discussion_entry.id.to_s
  end

  it 'queries the attributes' do
    expect(discussion_entry_type.resolve("message")).to eq discussion_entry.message
    expect(discussion_entry_type.resolve("ratingSum")).to eq discussion_entry.rating_sum
    expect(discussion_entry_type.resolve("ratingCount")).to eq discussion_entry.rating_count
    expect(discussion_entry_type.resolve("rating")).to eq discussion_entry.rating.present?
    expect(discussion_entry_type.resolve("deleted")).to eq discussion_entry.deleted?
    expect(discussion_entry_type.resolve("read")).to eq discussion_entry.read?
    expect(discussion_entry_type.resolve("author { _id }")).to eq discussion_entry.user_id.to_s
    expect(discussion_entry_type.resolve("editor { _id }")).to eq discussion_entry.editor_id.to_s
    expect(discussion_entry_type.resolve("discussionTopic { _id }")).to eq discussion_entry.discussion_topic.id.to_s
  end

  it 'returns the quoted reply html for reply preview' do
    Account.site_admin.enable_feature!(:isolated_view)
    expect(discussion_entry_type.resolve("replyPreview")).to eq discussion_entry.quoted_reply_html
  end

  it 'allows querying for discussion subentries' do
    de = discussion_entry.discussion_topic.discussion_entries.create!(message: 'sub entry', user: @teacher, parent_id: discussion_entry.id)

    result = discussion_entry_type.resolve('discussionSubentriesConnection { nodes { message } }')
    expect(result.count).to be 1
    expect(result[0]).to eq de.message
  end

  it 'allows querying for discussion subentries with sort' do
    discussion_entry.discussion_topic.discussion_entries.create!(message: 'sub entry', user: @teacher, parent_id: discussion_entry.id)
    de1 = discussion_entry.discussion_topic.discussion_entries.create!(message: 'sub entry 1', user: @teacher, parent_id: discussion_entry.id)

    result = discussion_entry_type.resolve('discussionSubentriesConnection(sortOrder: desc) { nodes { message } }')
    expect(result.count).to be 2
    expect(result[0]).to eq de1.message
  end

  it 'allows querying for the last subentry' do
    de = discussion_entry
    4.times do |i|
      de = discussion_entry.discussion_topic.discussion_entries.create!(message: "sub entry #{i}", user: @teacher, parent_id: de.id)
    end

    result = discussion_entry_type.resolve('lastReply { message }')
    expect(result).to eq de.message
  end

  it 'allows querying for participant counts' do
    3.times { discussion_entry.discussion_topic.discussion_entries.create!(message: "sub entry", user: @teacher, parent_id: discussion_entry.id) }

    expect(discussion_entry_type.resolve('rootEntryParticipantCounts { unreadCount }')).to eq 0
    expect(discussion_entry_type.resolve('rootEntryParticipantCounts { repliesCount }')).to eq 3
    DiscussionEntryParticipant.where(user_id: @teacher).update_all(workflow_state: 'unread')
    expect(discussion_entry_type.resolve('rootEntryParticipantCounts { unreadCount }')).to eq 3
    expect(discussion_entry_type.resolve('rootEntryParticipantCounts { repliesCount }')).to eq 3
  end

  it 'does not allows querying for participant counts on non root_entries' do
    child = discussion_entry.discussion_topic.discussion_entries.create!(message: "sub entry", user: @teacher, parent_id: discussion_entry.id)
    de_type = GraphQLTypeTester.new(child, current_user: @teacher)
    expect(de_type.resolve('rootEntryParticipantCounts { unreadCount }')).to be_nil
  end

  it 'returns a null message when entry is marked as deleted' do
    discussion_entry.destroy
    expect(discussion_entry_type.resolve("message")).to eq nil
  end

  it 'returns subentries count' do
    4.times do |i|
      discussion_entry.discussion_topic.discussion_entries.create!(message: "sub entry #{i}", user: @teacher, parent_id: discussion_entry.id)
    end

    expect(discussion_entry_type.resolve('subentriesCount')).to eq 4
  end

  it 'returns the current user permissions' do
    student_in_course(active_all: true)
    type = GraphQLTypeTester.new(discussion_entry, current_user: @student)

    permissions.each do |permission|
      expect(type.resolve("permissions { #{permission[:value]} }")).to eq permission[:allowed].call(@student)

      expect(discussion_entry_type.resolve("permissions { #{permission[:value]} }")).to eq permission[:allowed].call(@teacher)
    end
  end

  describe "forced_read_state attribute" do
    context "forced_read_state is nil" do
      before do
        discussion_entry.update_or_create_participant({current_user:@teacher, forced:nil})
      end

      it 'returns false' do
        expect(discussion_entry_type.resolve("forcedReadState")).to be false
      end
    end

    context "forced_read_state is false" do
      before do
        discussion_entry.update_or_create_participant({current_user:@teacher, forced:false})
      end

      it 'returns false' do
        expect(discussion_entry_type.resolve("forcedReadState")).to be false
      end
    end

    context "forced_read_state is true" do
      before do
        discussion_entry.update_or_create_participant({current_user:@teacher, forced:true})
      end
      
      it 'returns true' do
        expect(discussion_entry_type.resolve("forcedReadState")).to be true
      end
    end
  end

  it 'returns the root entry if there is one' do
    de = discussion_entry.discussion_topic.discussion_entries.create!(message: "sub entry", user: @teacher, parent_id: discussion_entry.id)

    expect(discussion_entry_type.resolve('rootEntry { _id }')).to be nil

    sub_entry_type = GraphQLTypeTester.new(de, current_user: @teacher)
    expect(sub_entry_type.resolve('rootEntry { _id }')).to eq discussion_entry.id.to_s
  end

end
