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

require 'spec_helper'
require_relative '../graphql_spec_helper'

RSpec.describe Mutations::UpdateDiscussionEntryParticipant do
  before(:once) do
    @discussion_entry = create_valid_discussion_entry
  end

  def mutation_str(
    id: nil,
    read: nil,
    rating: nil,
    forcedReadState: nil
  )
    <<~GQL
      mutation {
        updateDiscussionEntryParticipant(input: {
          discussionEntryId: #{id}
          #{"read: #{read}" unless read.nil?}
          #{"rating: #{rating}" if rating}
          #{"forcedReadState: #{forcedReadState}" unless forcedReadState.nil?}
        }) {
          discussionEntry {
            read
            rating
            ratingSum
            forcedReadState
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @discussion_entry.user)
    result = CanvasSchema.execute(
      mutation_str(opts),
      context: {
        current_user: current_user,
        domain_root_account: @discussion_entry.discussion_topic.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it 'updates the read state' do
    expect(@discussion_entry.read?(@discussion_entry.user)).to be true
    result = run_mutation({id: @discussion_entry.id, read: false})
    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'read')).to be false
    @discussion_entry.reload
    expect(@discussion_entry.read?(@discussion_entry.user)).to be false
  end

  it 'updates the entry rating' do
    @discussion_entry.discussion_topic.update!(allow_rating: true)
    expect(@discussion_entry.rating(@discussion_entry.user)).to be nil
    result = run_mutation({id: @discussion_entry.id, rating: 'liked'})

    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'rating')).to be true
    expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'ratingSum')).to eq 1
    expect(@discussion_entry.rating(@discussion_entry.user)).to be_equal 1
  end

  describe "forcedReadState attribute mutations" do
    context "force setting read to false" do
      it 'updates the forcedReadState to true' do
        expect(@discussion_entry.read?(@discussion_entry.user)).to be true
        result = run_mutation({id: @discussion_entry.id, read: false, forcedReadState:true})
        expect(result.dig('errors')).to be nil
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'read')).to be false
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'forcedReadState')).to be true
        @discussion_entry.reload
        expect(@discussion_entry.read?(@discussion_entry.user)).to be false
        expect(@discussion_entry.find_existing_participant(@discussion_entry.user).forced_read_state).to be true
      end
      it 'updates the forcedReadState to false' do
        expect(@discussion_entry.read?(@discussion_entry.user)).to be true
        result = run_mutation({id: @discussion_entry.id, read: false, forcedReadState:false})
        expect(result.dig('errors')).to be nil
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'read')).to be false
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'forcedReadState')).to be false
        @discussion_entry.reload
        expect(@discussion_entry.read?(@discussion_entry.user)).to be false
        expect(@discussion_entry.find_existing_participant(@discussion_entry.user).forced_read_state).to be false
      end
    end

    context "force setting read to true" do
      before do
        @discussion_entry.change_read_state('unread', @discussion_entry.user)
      end
      it 'updates the forcedReadState to true' do
        expect(@discussion_entry.read?(@discussion_entry.user)).to be false
        result = run_mutation({id: @discussion_entry.id, read: true, forcedReadState:true})
        expect(result.dig('errors')).to be nil
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'read')).to be true
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'forcedReadState')).to be true
        @discussion_entry.reload
        expect(@discussion_entry.read?(@discussion_entry.user)).to be true
        expect(@discussion_entry.find_existing_participant(@discussion_entry.user).forced_read_state).to be true
      end
      it 'updates the forcedReadState to false' do
        expect(@discussion_entry.read?(@discussion_entry.user)).to be false
        result = run_mutation({id: @discussion_entry.id, read: true, forcedReadState:false})
        expect(result.dig('errors')).to be nil
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'read')).to be true
        expect(result.dig('data', 'updateDiscussionEntryParticipant', 'discussionEntry', 'forcedReadState')).to be false
        @discussion_entry.reload
        expect(@discussion_entry.read?(@discussion_entry.user)).to be true
        expect(@discussion_entry.find_existing_participant(@discussion_entry.user).forced_read_state).to be false
      end
    end
  end
end
