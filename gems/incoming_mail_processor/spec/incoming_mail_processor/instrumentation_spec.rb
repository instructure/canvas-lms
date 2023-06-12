# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "spec_helper"

describe IncomingMailProcessor::Instrumentation do
  let(:mailbox) do
    obj = double
    allow(obj).to receive(:unprocessed_message_count).and_return(4, nil, 0, 50)
    obj
  end

  let(:single_config) do
    { "imap" => {
      "address" => "fake@fake.fake"
    } }
  end

  let(:multi_config) do
    { "imap" => {
      "accounts" => [
        { "username" => "user1@fake.fake" },
        { "username" => "user2@fake.fake" },
        { "username" => "user3@fake.fake" },
        { "username" => "user4@fake.fake" },
      ],
    }, }
  end

  describe ".process" do
    before do
      allow(IncomingMailProcessor::IncomingMessageProcessor).to receive(:create_mailbox).and_return(mailbox)
    end

    it "pushes to statsd for one mailbox" do
      IncomingMailProcessor::IncomingMessageProcessor.configure(single_config)

      expect(InstStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.fake@fake_fake",
                                                         4,
                                                         { short_stat: "incoming_mail_processor.mailbox_queue_size",
                                                           tags: { identifier: "fake@fake_fake" } })

      IncomingMailProcessor::Instrumentation.process
    end

    it "pushes to statsd for multiple mailboxes" do
      IncomingMailProcessor::IncomingMessageProcessor.configure(multi_config)

      expect(InstStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.user1@fake_fake",
                                                         4,
                                                         { short_stat: "incoming_mail_processor.mailbox_queue_size",
                                                           tags: { identifier: "user1@fake_fake" } })
      expect(InstStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.user3@fake_fake",
                                                         0,
                                                         { short_stat: "incoming_mail_processor.mailbox_queue_size",
                                                           tags: { identifier: "user3@fake_fake" } })
      expect(InstStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.user4@fake_fake",
                                                         50,
                                                         { short_stat: "incoming_mail_processor.mailbox_queue_size",
                                                           tags: { identifier: "user4@fake_fake" } })

      IncomingMailProcessor::Instrumentation.process
    end
  end
end
