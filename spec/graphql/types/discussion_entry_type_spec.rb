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
  let(:discussion_entry) { create_valid_discussion_entry }
  let(:discussion_entry_type) { GraphQLTypeTester.new(discussion_entry, current_user: @teacher) }

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

  it 'returns a null message when entry is marked as deleted' do
    discussion_entry.destroy
    expect(discussion_entry_type.resolve("message")).to eq nil
  end
end
