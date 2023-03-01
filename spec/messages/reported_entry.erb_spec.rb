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
      msg = generate_message(notification_name, path_type, asset, data: { report_type: "offensive" })
      expect(msg.url).to include "/courses/#{@topic.context.id}/discussion_topics/#{@topic.id}?entry_id=#{@object.id}#entry-#{@object.id}"
      expect(msg.subject).to include "Reported reply in #{@topic.title}, #{@topic.context.name}"
      expect(msg.body).to include "Reported as offensive: #{@object.author_name}, #{@object.context.name}"
      expect(msg.html_body).to include "Reported as offensive: #{@object.author_name}, #{@object.context.name}"
      expect(msg.body).to include "View the discussion:"
      expect(msg.html_body).to include "View the reply in the discussion using the link below."
    end

    it "renders anonymous user if discussion is anonymous" do
      real_author_name = @object.author_name
      @topic.anonymous_state = "full_anonymity"
      @topic.save!

      msg = generate_message(notification_name, path_type, asset, data: { report_type: "offensive" })
      expect(@object.author_name).not_to include real_author_name
      expect(@object.author_name).to include "Anonymous"
      expect(msg.body).to include "Reported as offensive: #{@object.author_name}, #{@object.context.name}"
      expect(msg.html_body).to include "Reported as offensive: #{@object.author_name}, #{@object.context.name}"
    end
  end

  describe "summary" do
    let(:path_type) { :summary }

    it "renders summary" do
      msg = generate_message(notification_name, path_type, asset, data: { report_type: "offensive" })
      expect(msg.subject).to include "Reported reply in #{@topic.title}, #{@topic.context.name}"
    end
  end
end
