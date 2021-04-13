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
    rating: nil
  )
    <<~GQL
      mutation {
        updateDiscussionEntryParticipant(input: {
          discussionEntryId: #{id}
          #{"read: #{read}" unless read.nil?}
          #{"rating: #{rating}" if rating}
        }) {
          discussionEntry {
            read
            rating
            ratingSum
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
end
