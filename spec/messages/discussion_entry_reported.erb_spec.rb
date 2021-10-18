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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'discussion_entry_reported' do
  before :once do
    discussion_topic_model
    entry = @topic.discussion_entries.create!(user: user_model)
    @object = entry.mentions.create!(user: @user, root_account: entry.root_account)
  end

  let(:asset) { @object }
  let(:notification_name) { :new_discussion_mention }

  include_examples "a message"

  describe "email" do
    let(:path_type) { :email }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.url).to match(/\/courses\/\d+\/discussion_topics\/\d+/)
      expect(msg.body).to match(/\/courses\/\d+\/discussion_topics\/\d+/)
    end
  end
end
