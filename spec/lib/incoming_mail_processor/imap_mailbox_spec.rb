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

require File.expand_path('../../../../lib/incoming_mail_processor/imap_mailbox', __FILE__)
require File.expand_path('../../../mocha_rspec_adapter', __FILE__)
require File.expand_path('../mailbox_spec_helper', __FILE__)

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

    Net::IMAP.expects(:new).
      with("mail.example.com", {:port => 993, :ssl => true}).
      times(0..1). # allow simple tests to not call #connect
      returns(@imap_mock)
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

      @mailbox.server.should eql "imap.server.com"
      @mailbox.port.should eql 1234
      @mailbox.ssl.should eql "truthy-value"
      @mailbox.filter.should eql ["ALL"]
      @mailbox.username.should eql "user@server.com"
      @mailbox.password.should eql "secret-user-password"
    end

    it "should accept non-array filter" do
      @mailbox = IncomingMailProcessor::ImapMailbox.new(:filter => "BLAH")
      @mailbox.filter.should eql ["BLAH"]
    end

    it "should accept folder parameter" do
      # this isn't necessary for gmail, but just in case
      @mailbox = IncomingMailProcessor::ImapMailbox.new(:folder => "inbox")
      @mailbox.folder.should eql "inbox"
    end

  end

  describe "connect" do
    it "should connect to the server" do
      @imap_mock.expects(:login).with("user", "password").once
      @mailbox.connect
    end
  end

  context "connected" do
    before do
      @mailbox.connect
    end

    def mock_fetch_response(body)
      result = mock()
      result.expects(:attr).returns({"RFC822" => body})
      [result]
    end

    it "should retrieve and yield messages" do
      @mailbox.folder = "message_folder"
      @imap_mock.expects(:select).with("message_folder").once
      @imap_mock.expects(:search).with(["ALL"]).once.returns([1, 2, 3])

      fetch = sequence('fetch')
      @imap_mock.expects(:fetch).in_sequence(fetch).with(1, "RFC822").returns(mock_fetch_response("foo"))
      @imap_mock.expects(:fetch).in_sequence(fetch).with(2, "RFC822").returns(mock_fetch_response("bar"))
      @imap_mock.expects(:fetch).in_sequence(fetch).with(3, "RFC822").returns(mock_fetch_response("baz"))
      @imap_mock.expects(:expunge).with().once

      yielded_values = []
      @mailbox.each_message do |message_id, message_body|
        yielded_values << [message_id, message_body]
      end
      yielded_values.should eql [[1, "foo"], [2, "bar"], [3, "baz"]]
    end

    it "should delete a retrieved message" do
      @imap_mock.expects(:search).returns([42])
      @imap_mock.expects(:fetch).returns(mock_fetch_response("body"))
      @imap_mock.expects(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.delete_message(id)
      end
    end

    it "should move a retrieved message" do
      @imap_mock.expects(:search).returns([42])
      @imap_mock.expects(:fetch).returns(mock_fetch_response("body"))
      @imap_mock.expects(:list).returns([stub_everything])
      @imap_mock.expects(:copy).with(42, "other_folder")
      @imap_mock.expects(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "other_folder")
      end
    end

    it "should create the folder if necessary when moving a message (imap list returns empty)" do
      @imap_mock.expects(:search).returns([42])
      @imap_mock.expects(:fetch).returns(mock_fetch_response("body"))
      @imap_mock.expects(:list).with("", "other_folder").returns([])
      @imap_mock.expects(:create).with("other_folder")
      @imap_mock.expects(:copy).with(42, "other_folder")
      @imap_mock.expects(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "other_folder")
      end
    end

    it "should create the folder if necessary when moving a message (imap list returns nil)" do
      @imap_mock.expects(:search).returns([42])
      @imap_mock.expects(:fetch).returns(mock_fetch_response("body"))
      @imap_mock.expects(:list).with("", "other_folder").returns(nil)
      @imap_mock.expects(:create).with("other_folder")
      @imap_mock.expects(:copy).with(42, "other_folder")
      @imap_mock.expects(:store).with(42, "+FLAGS", Net::IMAP::DELETED)
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "other_folder")
      end
    end
      
  end

  describe "#disconnect" do
    it "should disconnect" do
      @mailbox.connect
      @imap_mock.expects(:logout)
      @imap_mock.expects(:disconnect)
      @mailbox.disconnect
    end
  end

  describe "timeouts" do
    it "should use timeout method on connect call" do
      @mailbox.set_timeout_method { raise Timeout::Error }
      lambda { @mailbox.connect }.should raise_error(Timeout::Error)
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
      exception_propegated.should be_true
    end


  end
end
