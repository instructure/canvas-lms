# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require "spec_helper"

describe IncomingMailProcessor::Pop3Mailbox do
  include_examples "Mailbox"

  def default_config
    {
      server: "mail.example.com",
      ssl: false,
      port: 2345,
      username: "user",
      password: "password",
    }
  end

  def mock_net_pop
    @pop_mock = double
    IncomingMailProcessor::Pop3Mailbox::UsedPopMethods.each do |method_name|
      allow(@pop_mock).to receive(method_name)
    end

    allow(Net::POP3).to receive(:new).and_return(@pop_mock)
  end

  describe "#initialize" do
    it "accepts existing mailman pop3 configuration" do
      @mailbox = IncomingMailProcessor::Pop3Mailbox.new({
                                                          server: "pop3.server.com",
                                                          port: 1234,
                                                          ssl: "truthy-value",
                                                          username: "user@server.com",
                                                          password: "secret-user-password",
                                                        })

      expect(@mailbox.server).to eql "pop3.server.com"
      expect(@mailbox.port).to be 1234
      expect(@mailbox.ssl).to eql "truthy-value"
      expect(@mailbox.username).to eql "user@server.com"
      expect(@mailbox.password).to eql "secret-user-password"
    end
  end

  describe "#connect" do
    before do
      mock_net_pop
    end

    it "connects to the server" do
      config = default_config.merge(ssl: false, port: 110)
      expect(Net::POP3).to receive(:new).with(config[:server], config[:port]).and_return(@pop_mock)
      expect(@pop_mock).to receive(:start).with(config[:username], config[:password])

      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(config)
      @mailbox.connect
    end

    it "uses ssl if configured" do
      config = default_config.merge(ssl: true, port: 995)

      expect(Net::POP3).to receive(:new).with(config[:server], config[:port]).and_return(@pop_mock)
      expect(@pop_mock).to receive(:enable_ssl).with(OpenSSL::SSL::VERIFY_PEER)
      expect(@pop_mock).to receive(:start).with(config[:username], config[:password])

      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(config)
      @mailbox.connect
    end
  end

  describe "#disconnect" do
    it "disconnects" do
      mock_net_pop
      expect(@pop_mock).to receive(:finish)

      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(default_config)
      @mailbox.connect
      @mailbox.disconnect
    end
  end

  describe "#unprocessed_message_count" do
    it "returns nil" do
      expect(IncomingMailProcessor::Pop3Mailbox.new(default_config).unprocessed_message_count).to be_nil
    end
  end

  describe "#each_message" do
    before do
      mock_net_pop
      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(default_config)
      @mailbox.connect
    end

    it "retrieves and yield messages" do
      foo = double(pop: "foo body")
      bar = double(pop: "bar body")
      baz = double(pop: "baz body")
      expect(@pop_mock).to receive(:mails).and_return([foo, bar, baz])

      yielded_values = []
      @mailbox.each_message do |message_id, body|
        yielded_values << [message_id, body]
      end

      expect(yielded_values).to eql [[foo, "foo body"], [bar, "bar body"], [baz, "baz body"]]
    end

    it "retrieves messages using a stride and offset" do
      foo, bar, baz = %w[foo bar baz].map do |msg|
        m = double(pop: "#{msg} body")
        expect(m).to receive(:uidl).twice.and_return(msg)
        m
      end
      expect(@pop_mock).to receive(:mails).twice.and_return([foo, bar, baz])

      yielded_values = []
      @mailbox.each_message(stride: 2, offset: 0) do |message_id, body|
        yielded_values << [message_id, body]
      end
      expect(yielded_values).to eql [[bar, "bar body"], [baz, "baz body"]]

      yielded_values = []
      @mailbox.each_message(stride: 2, offset: 1) do |message_id, body|
        yielded_values << [message_id, body]
      end
      expect(yielded_values).to eql [[foo, "foo body"]]
    end

    context "with simple foo message" do
      before do
        @foo = double(pop: "foo body")
        expect(@pop_mock).to receive(:mails).and_return([@foo])
      end

      it "deletes when asked" do
        expect(@foo).to receive(:delete)
        @mailbox.each_message do |message_id, _body|
          @mailbox.delete_message(message_id)
        end
      end

      it "deletes when asked to move" do
        expect(@foo).to receive(:delete)
        @mailbox.each_message do |message_id, _body|
          @mailbox.move_message(message_id, "anything")
        end
      end
    end
  end
end
