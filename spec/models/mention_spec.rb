# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Mention do
  before do
    @user = User.create!(name: "Jim Bob")
    @topic = DiscussionTopic.create!(message: "Welcome friends", title: "Hello", context: course_model)
    @entry = @topic.discussion_entries.create!(message: "entry 1", user: @user)
  end

  describe "Metrics" do
    before do
      allow(InstStatsd::Statsd).to receive(:increment)
    end

    it "increment discussion_mention.created" do
      Mention.create!(user_id: @user.id, discussion_entry_id: @entry.id, root_account_id: @topic.root_account_id)
      expect(InstStatsd::Statsd).to have_received(:increment).with("discussion_mention.created")
    end
  end
end
