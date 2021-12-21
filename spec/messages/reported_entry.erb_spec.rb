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

require_relative "messages_helper"

describe "reported_reply" do
  before :once do
    discussion_topic_model
    @object = @topic.discussion_entries.create!(user: user_model)
  end

  let(:asset) { @object }
  let(:notification_name) { :reported_reply }

  include_examples "a message"

  describe "email" do
    let(:path_type) { :email }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.url).to match(%r{/courses/\d+/discussion_topics/\d+})
      expect(msg.body).to match(%r{/courses/\d+/discussion_topics/\d+})
      expect(msg.html_body.include?("View the reply in the discussion: \n<a href=\"http://localhost/courses/#{@object.discussion_topic.course.id}/discussion_topics/#{@object.discussion_topic.id}?entry_id=#{@object.id}\">")).to eq(true)
    end

    it "renders anonymous user if discussion is anonymous" do
      @topic.anonymous_state = "full_anonymity"
      @topic.save!

      msg = generate_message(notification_name, path_type, asset)
      expect(msg.html_body.include?("Anonymous")).to eq(true)
    end
  end
end
