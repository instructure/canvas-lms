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

describe "announcement_reply" do
  include MessagesCommon

  before :once do
    course_with_teacher(active_all: true)
    @announcement = announcement_model(user: @teacher, discussion_type: "threaded")
    @announcement.reply_from(user: @teacher, text: "hai")
    @entry = @announcement.discussion_entries.last
  end

  let(:notification_name) { :announcement_reply }
  let(:asset) { @entry }

  context ".email" do
    let(:path_type) { :email }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to eq "New Comment on Announcement value for title: value for name"
      expect(msg.url).to include "/courses/#{@announcement.context.id}/discussion_topics/#{@announcement.id}?entry_id=#{@entry.id}#entry-#{@entry.id}"
      expect(msg.body).to match(%r{/courses/\d+/discussion_topics/\d+})
    end

    it "renders correct footer if replys are enabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = true
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body.include?("replying to this message")).to be true
    end

    it "renders correct footer if replys are disabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = false
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body.include?("replying to this message")).to be false
    end

    it "the url to the image should exist on the internet" do
      # this is the image we are counting on in our templates to exist, if it ever gets removed from the internet
      # we need to do something about it
      expect(Faraday.head("https://du11hjcvx0uqb.cloudfront.net/dist/images/email_signature-d2c5880612.png").status).to eq 200
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
      expect(msg.subject).to eq "New Comment on Announcement: value for title: value for name"
      expect(msg.url).to include "/courses/#{@announcement.context.id}/discussion_topics/#{@announcement.id}?entry_id=#{@entry.id}#entry-#{@entry.id}"
      expect(msg.body.strip).to eq "hai"
    end
  end

  context ".twitter" do
    let(:path_type) { :twitter }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to eq "Canvas Alert"
      expect(msg.url).to include "/courses/#{@announcement.context.id}/discussion_topics/#{@announcement.id}?entry_id=#{@entry.id}#entry-#{@entry.id}"
      expect(msg.body).to include("Canvas Alert - Announcement Comment: value for title, value for name")
    end
  end
end
