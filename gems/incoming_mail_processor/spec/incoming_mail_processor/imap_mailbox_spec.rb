#
# Copyright (C) 2013 Instructure, Inc.
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

require 'spec_helper'

describe IncomingMailProcessor::ImapMailbox do
  include_examples 'Mailbox'

  def default_config
    {
      :server => "mail.example.com",
      :username => "user",
      :password => "password",
    }
  end

  def mock_net_imap
    @imap_mock = Object.new
    class <<@imap_mock
      IncomingMailProcessor::ImapMailbox::UsedImapMethods.each do |method_name|
        define_method(method_name) { |*args, &block| }
      end
    end

    expect(Net::IMAP).to receive(:new).
      with("mail.example.com", {:port => 993, :ssl => true}).
      at_most(:once). # allow simple tests to not call #connect
      and_return(@imap_mock)
  end

  before do
    mock_net_imap
    @mailbox = IncomingMailProcessor::ImapMailbox.new(default_config)
  end

  describe "#initialize" do
    it "should accept existing mailman imap configuration" do
      @mailbox = IncomingMailProcessor::ImapMailbox.new({
        :server => "imap.server.com",
        :port => 1234,
        :ssl => "truthy-value",
        :filter => ["ALL"],
        :username => "user@server.com",
        :password => "secret-user-password",
      })

      expect(@mailbox.server).to eql "imap.server.com"
      expect(@mailbox.port).to eql 1234
      expect(@mailbox.ssl).to eql "truthy-value"
      expect(@mailbox.filter).to eql ["ALL"]
      expect(@mailbox.username).to eql "user@server.com"
      expect(@mailbox.password).to eql "secret-user-password"
    end

    it "should accept non-array filter" do
      @mailbox = IncomingMailProcessor::ImapMailbox.new(:filter => "BLAH")
      expect(@mailbox.filter).to eql ["BLAH"]
    end

    it "should accept folder parameter" do
      # this isn't necessary for gmail, but just in case
      @mailbox = IncomingMailProcessor::ImapMailbox.new(:folder => "inbox")
      expect(@mailbox.folder).to eql "inbox"
    end

  end

  describe "connect" do
    it "should connect to the server" do
      expect(@imap_mock).to receive(:login).with("user", "password").once
      @mailbox.connect
    end
  end

  describe '#unprocessed_message_count' do
    it 'returns zero if there are no messages' do
      expect(@imap_mock).to receive(:search).with(["X-GM-RAW", "label:unread"]).once.and_return([])
      expect(@mailbox.unprocessed_message_count).to eql 0
    end

    it 'returns the number of messages if there are any' do
      expect(@imap_mock).to receive(:search).with(["X-GM-RAW", "label:unread"]).once.and_return([1,2,3,58,42])
      expect(@mailbox.unprocessed_message_count).to eql 5
    end
  end

  context "connected" do
    before do
      @mailbox.connect
    end

    def mock_fetch_response(body)
      result = double()
      expect(result).to receive(:attr).and_return({"RFC822" => body})
      [result]
    end

    it "should retrieve and yield messages" do
      @mailbox.folder = "message_folder"
      expect(@imap_mock).to receive(:select).with("message_folder").once
      expect(@imap_mock).to receive(:search).with(["ALL"]).once.and_return([1, 2, 3])

      expect(@imap_mock).to receive(:fetch).with(1, "RFC822").and_return(mock_fetch_response("foo")).ordered
      expect(@imap_mock).to receive(:fetch).with(2, "RFC822").and_return(mock_fetch_response("bar")).ordered
      expect(@imap_mock).to receive(:fetch).with(3, "RFC822").and_return(mock_fetch_response("baz")).ordered
      expect(@imap_mock).to receive(:expunge).once

      yielded_values = []
      @mailbox.each_message do |message_id, message_body|
        yielded_values << [message_id, message_body]
      end
      expect(yielded_values).to eql [[1, "foo"], [2, "bar"], [3, "baz"]]
    end

    it "retrieves messages uses stride and offset" do
      @mailbox.folder = "message_folder"
      expect(@imap_mock).to receive(:select).with("message_folder").twice
      expect(@imap_mock).to receive(:search).with(["ALL"]).twice.and_return([1, 2, 3])

      expect(@imap_mock).to receive(:fetch).with(2, "RFC822").and_return(mock_fetch_response("bar")).ordered
      expect(@imap_mock).to receive(:fetch).with(1, "RFC822").and_return(mock_fetch_response("foo")).ordered
      expect(@imap_mock).to receive(:fetch).with(3, "RFC822").and_return(mock_fetch_response("baz")).ordered
      expect(@imap_mock).to receive(:expunge).twice

      yielded_values = []
      @mailbox.each_message(stride: 2, offset: 0) do |message_id, message_body|
        yielded_values << [message_id, message_body]
      end
      expect(yielded_values).to eql [[2, "bar"]]

      yielded_values = []
      @mailbox.each_message(stride: 2, offset: 1) do |message_id, message_body|
        yielded_values << [message_id, message_body]
      end
      expect(yielded_values).to eql [[1, "foo"], [3, "baz"]]
    end

    it "should delete a retrieved message" do
      expect(@imap_mock).to receive(:search).and_return([42])
      expect(@imap_mock).to receive(:fetch).and_return(mock_fetch_response("body"))
      expect(@imap_mock).to receive(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.delete_message(id)
      end
    end

    it "should move a retrieved message" do
      expect(@imap_mock).to receive(:search).and_return([42])
      expect(@imap_mock).to receive(:fetch).and_return(mock_fetch_response("body"))
      expect(@imap_mock).to receive(:list).and_return([double.as_null_object])
      expect(@imap_mock).to receive(:copy).with(42, "other_folder")
      expect(@imap_mock).to receive(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "other_folder")
      end
    end

    it "should create the folder if necessary when moving a message (imap list returns empty)" do
      expect(@imap_mock).to receive(:search).and_return([42])
      expect(@imap_mock).to receive(:fetch).and_return(mock_fetch_response("body"))
      expect(@imap_mock).to receive(:list).with("", "other_folder").and_return([])
      expect(@imap_mock).to receive(:create).with("other_folder")
      expect(@imap_mock).to receive(:copy).with(42, "other_folder")
      expect(@imap_mock).to receive(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "other_folder")
      end
    end

    it "should create the folder if necessary when moving a message (imap list returns nil)" do
      expect(@imap_mock).to receive(:search).and_return([42])
      expect(@imap_mock).to receive(:fetch).and_return(mock_fetch_response("body"))
      expect(@imap_mock).to receive(:list).with("", "other_folder").and_return(nil)
      expect(@imap_mock).to receive(:create).with("other_folder")
      expect(@imap_mock).to receive(:copy).with(42, "other_folder")
      expect(@imap_mock).to receive(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "other_folder")
      end
    end
      
  end

  describe "#disconnect" do
    it "should disconnect" do
      @mailbox.connect
      expect(@imap_mock).to receive(:logout)
      expect(@imap_mock).to receive(:disconnect)
      @mailbox.disconnect
    end
  end

  describe "timeouts" do
    it "should use timeout method on connect call" do
      @mailbox.set_timeout_method { raise Timeout::Error }
      expect { @mailbox.connect }.to raise_error(Timeout::Error)
    end
    # if these work, others are likely wrapped with timeouts as well because of wrap_with_timeout

    # disconnect is allowed to swallow timeout errors
    it "should use timeout method on disconnect call" do
      @mailbox.connect
      @mailbox.set_timeout_method { raise Timeout::Error }
      @mailbox.disconnect #.should_not raise_error
      @mailbox.set_timeout_method { raise SyntaxError }

      # rspec .should raise_error doesn't catch outside of StandardError hierarchy
      exception_propegated = false
      begin
        @mailbox.disconnect
      rescue SyntaxError => e
        exception_propegated = true
      end
      expect(exception_propegated).to be_truthy
    end
  end
end
