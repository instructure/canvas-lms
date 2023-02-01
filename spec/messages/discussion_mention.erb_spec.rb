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

describe "discussion_mention" do
  before :once do
    discussion_topic_model
    @entry = @topic.discussion_entries.create!(user: user_model)
    @object = @entry.mentions.create!(user: @user, root_account: @entry.root_account)
  end

  let(:asset) { @object }
  let(:notification_name) { :discussion_mention }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }
    let(:long_comment_instruction_html) do
      "Comment by replying to this message, or join the conversation using the link below. When allowed, if you need to include an attachment, please log in to Canvas and reply to the discussion."
    end
    let(:long_comment_instruction_plain) do
      "Comment by replying to this message, or join the conversation using this link:"
    end

    it "renders emal" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.url).to include "/courses/#{@topic.context.id}/discussion_topics/#{@topic.id}?entry_id=#{@entry.id}#entry-#{@entry.id}"
    end

    it "renders correct footer if replies are enabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = true
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body).to include long_comment_instruction_plain
      expect(msg.html_body).to include long_comment_instruction_html
    end

    it "renders correct footer if replies are disabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = false
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body).not_to include long_comment_instruction_plain
      expect(msg.html_body).not_to include long_comment_instruction_html
      expect(msg.html_body).to include "Join the conversation using the link below."
      expect(msg.body).to include "Join the conversation using this link:"
    end
  end

  context "summary" do
    let(:path_type) { :summary }

    it "renders summary" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.url).to include "/courses/#{@topic.context.id}/discussion_topics/#{@topic.id}?entry_id=#{@entry.id}#entry-#{@entry.id}"
      expect(msg.subject).to include "You have been mentioned in #{@entry.title}: #{@course.name}"
    end
  end

  context "twitter" do
    let(:path_type) { :twitter }

    it "renders twitter" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.url).to include "/courses/#{@topic.context.id}/discussion_topics/#{@topic.id}?entry_id=#{@entry.id}#entry-#{@entry.id}"
      expect(msg.body).to include "Canvas Alert - Mention: #{@entry.title}, #{@course.name}."
    end
  end
end
