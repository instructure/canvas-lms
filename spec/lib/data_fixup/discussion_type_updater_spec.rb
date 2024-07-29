# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::DiscussionTypeUpdater do
  describe "DiscussionTypeUpdater" do
    let!(:account) { Account.create(id: 1) }
    let!(:course) { Course.create!(account:) }
    let!(:topic1) { DiscussionTopic.create!(discussion_type: "side_comment", workflow_state: "active", context: course) }
    let!(:topic2) { DiscussionTopic.create!(discussion_type: "side_comment", workflow_state: "active", context: course) }
    let!(:entry1) { DiscussionEntry.create(id: 1, discussion_topic: topic1, parent_id: nil, workflow_state: "active", root_account_id: account.id) }
    let!(:entry2) { DiscussionEntry.create(id: 2, discussion_topic: topic1, parent_id: entry1.id, workflow_state: "active", root_account_id: account.id) }
    let!(:entry3) { DiscussionEntry.create(id: 3, discussion_topic: topic1, parent_id: entry2.id, workflow_state: "active", root_account_id: account.id) }
    let!(:entry4) { DiscussionEntry.create(discussion_topic: topic2, parent_id: nil, workflow_state: "active", root_account_id: account.id) }

    it 'updates the discussion_type of topics with active, non-root entries to "threaded"' do
      DataFixup::DiscussionTypeUpdater.run

      expect(topic1.reload.discussion_type).to eq("threaded")
      expect(topic2.reload.discussion_type).to eq("side_comment")
    end
  end
end
