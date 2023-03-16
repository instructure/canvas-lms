# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "messages_helper"

describe "announcement_created_by_you" do
  include MessagesCommon

  before :once do
    @announcement = announcement_model
  end

  let(:notification_name) { :announcement_created_by_you }
  let(:asset) { @announcement }

  context ".email" do
    let(:path_type) { :email }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to eq "value for title: value for name"
      expect(msg.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(msg.body).to match(%r{/courses/\d+/announcements/\d+})
      expect(msg.body).to include("You created this Announcement:")
      expect(msg.html_body).to include("You created this Announcement:")
    end
  end

  context ".sms" do
    let(:path_type) { :sms }

    it "renders" do
      generate_message(notification_name, path_type, asset)
    end
  end

  context ".summary" do
    let(:path_type) { :summary }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to eq "value for title: value for name"
      expect(msg.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(msg.body.strip).to eq "value for message"
    end
  end

  context ".twitter" do
    let(:path_type) { :twitter }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to eq "Canvas Alert"
      expect(msg.url).to match(%r{/courses/\d+/announcements/\d+})
      expect(msg.body).to include("Canvas Alert - You created this Announcement: value for title")
    end
  end
end
