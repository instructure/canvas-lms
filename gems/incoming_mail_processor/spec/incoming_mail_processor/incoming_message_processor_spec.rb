#
# Copyright (C) 2011 Instructure, Inc.
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
describe IncomingMailProcessor::IncomingMessageProcessor do

  # Import this one constant
  IncomingMessageProcessor = IncomingMailProcessor::IncomingMessageProcessor

  let(:logger) { stub('logger').tap{|l| l.expects(:warn).at_least(1).with(kind_of(String))} }
  let(:message_handler) { MockMessageHandler.new }

  class MockMessageHandler
    attr_reader :account, :body, :html_body, :incoming_message, :address_tag

    def handle(account, body, html_body, incoming_message, tag)
      @account = account
      @body = body
      @html_body = html_body
      @incoming_message = incoming_message
      @address_tag = tag
    end
  end

  let(:error_reporter) { MockErrorReporter.new }

  class MockErrorReporter
    def log_error(category, opts)
    end

    def log_exception(category, exception, opts)
    end
  end

  before(:each) do
    error_reporter.expects(:log_exception).never
    error_reporter.expects(:log_error).never
  end

  describe ".configure" do
    it "should raise on invalid configuration settings" do
      expect { IncomingMessageProcessor.configure('bogus_setting' => 42) }.to raise_error(StandardError)
    end

    it "should accept legacy mailman configurations" do
      IncomingMessageProcessor.logger = logger
      IncomingMessageProcessor.configure('poll_interval' => 42, 'ignore_stdin' => true)
    end
  end

  describe ".run_periodically?" do
    it "should consult .poll_interval and .ignore_stdin for backwards compatibility" do
      IncomingMessageProcessor.logger = logger
      IncomingMessageProcessor.configure('poll_interval' => 0, 'ignore_stdin' => true)
      IncomingMessageProcessor.run_periodically?.should be_true

      IncomingMessageProcessor.configure('poll_interval' => 0, 'ignore_stdin' => false)
      IncomingMessageProcessor.run_periodically?.should be_false

      IncomingMessageProcessor.configure('poll_interval' => 42, 'ignore_stdin' => true)
      IncomingMessageProcessor.run_periodically?.should be_false
    end

    it "should use 'run_periodically' configuration setting" do
      IncomingMessageProcessor.configure({})
      IncomingMessageProcessor.run_periodically?.should be_false

      IncomingMessageProcessor.configure('run_periodically' => true)
      IncomingMessageProcessor.run_periodically?.should be_true
    end
  end

  describe "#process_single" do
    it "should not choke on invalid UTF-8" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new { body "he\xffllo" }, '')

      message_handler.body.should == "hello"
      message_handler.html_body.should == "hello"
    end

    it "should convert another charset to UTF-8" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new {
          content_type 'text/plain; charset=Shift-JIS'
          body "\x83\x40"
        }, '')

      comparison_string = "\xe3\x82\xa1"
      comparison_string.force_encoding("UTF-8")
      message_handler.body.should == comparison_string
      message_handler.html_body.should == comparison_string
    end

    it "should pick up html from a multipart" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new {
          text_part do
            body 'This is plain text'
          end
          html_part do
            content_type 'text/html; charset=UTF-8'
            body '<h1>This is HTML</h1>'
          end
        }, '')
      message_handler.body.should == 'This is plain text'
      message_handler.html_body.should == '<h1>This is HTML</h1>'
    end

    it "should not send a bounce reply when the incoming message is an auto-response" do
      incoming_bounce_message = Mail.new
      incoming_bounce_message['Auto-Submitted'] = 'auto-generated' # but don't bounce with this header

      message_handler.expects(:handle).never

      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(incoming_bounce_message, '')
    end
  end

  describe "#process" do
    before(:each) do
      @mock_mailbox = mock
      IncomingMessageProcessor.stubs(:create_mailbox => @mock_mailbox)
    end

    it "should support original incoming_mail configuration format for a single inbox" do
      IncomingMessageProcessor.logger = logger
      config = {
        'poll_interval' => 42,
        'ignore_stdin' => true,
        'imap' => {
          'server' => "fake",
          'port' => 4422,
          'username' => "fake@fake.fake",
          'password' => "fake",
          'ssl' => true,
          'filter' => ['ALL'],
        }
      }

      IncomingMessageProcessor.expects(:create_mailbox).returns(@mock_mailbox).with do |account|
        account.protocol == :imap &&
        account.config == config['imap'].symbolize_keys
      end
      IncomingMessageProcessor.configure(config)

      @mock_mailbox.expects(:connect)
      @mock_mailbox.expects(:each_message)
      @mock_mailbox.expects(:disconnect)
      IncomingMessageProcessor.new(message_handler, error_reporter).process
    end

    it "should process incoming_mail configuration with multiple accounts" do
      IncomingMessageProcessor.logger = logger
      config = {
        'poll_interval' => 0,
        'ignore_stdin' => true,
        'imap' => {
          'server' => "fake",
          'username' => 'should_be_overridden@fake.fake',
          'accounts' => [
            { 'username' => 'user1@fake.fake', 'password' => 'pass1' },
            { 'username' => 'user2@fake.fake', 'password' => 'pass2' },
            { 'username' => 'user3@fake.fake', 'password' => 'pass3' },
          ],
        },
      }

      seq = sequence('create_mailbox')
      imp = IncomingMessageProcessor
      imp.expects(:create_mailbox).in_sequence(seq).returns(@mock_mailbox).with do |account|
        account.protocol == :imap &&
        account.config == { :server => 'fake', :username => 'user1@fake.fake', :password => 'pass1'}
      end
      imp.expects(:create_mailbox).in_sequence(seq).returns(@mock_mailbox).with do |account|
        account.protocol == :imap &&
        account.config == { :server => 'fake', :username => 'user2@fake.fake', :password => 'pass2'}
      end
      imp.expects(:create_mailbox).in_sequence(seq).returns(@mock_mailbox).with do |account|
        account.protocol == :imap &&
        account.config == { :server => 'fake', :username => 'user3@fake.fake', :password => 'pass3'}
      end

      @mock_mailbox.expects(:connect).times(3)
      @mock_mailbox.expects(:each_message).times(3)
      @mock_mailbox.expects(:disconnect).times(3)

      IncomingMessageProcessor.configure(config)
      IncomingMessageProcessor.new(message_handler, error_reporter).process
    end

    it "should extract special values from account settings" do
      config = {
        'imap' => {
          'server' => 'fake',
          'username' => 'user@fake.fake',
          'password' => 'fake',
          'error_folder' => 'broken',
        },
      }

      IncomingMailProcessor::MailboxAccount.expects(:new).with({
        :protocol => :imap,
        :address => 'user@fake.fake',
        :error_folder => 'broken',
        :config => config['imap'].except('error_folder').symbolize_keys,
      })
      IncomingMessageProcessor.configure(config)
    end

    describe "message processing" do
      before do
        IncomingMessageProcessor.configure({
          'imap' => {
            'username' => 'me@fake.fake',
            'error_folder' => 'errors_go_here',
          }
        })
      end

      it "should perform normal message processing of messages retrieved from mailbox" do
        foo = "To: me+123-1@fake.fake\r\n\r\nfoo body"
        bar = "To: me+456-2@fake.fake\r\n\r\nbar body"
        baz = "To: me+abc-3@fake.fake\r\n\r\nbaz body"

        @mock_mailbox.expects(:connect)
        @mock_mailbox.expects(:move_message).never
        @mock_mailbox.expects(:delete_message).with(:foo)
        @mock_mailbox.expects(:delete_message).with(:bar)
        @mock_mailbox.expects(:delete_message).with(:baz)
        @mock_mailbox.expects(:each_message).multiple_yields([:foo, foo], [:bar, bar], [:baz, baz])
        @mock_mailbox.expects(:disconnect)
        imp = IncomingMessageProcessor.new(message_handler, error_reporter)
        imp.expects(:process_single).with(kind_of(Mail::Message), "123-1", anything)
        imp.expects(:process_single).with(kind_of(Mail::Message), "456-2", anything)
        imp.expects(:process_single).with(kind_of(Mail::Message), "abc-3", anything)

        imp.process
      end

      it "should process messages that have irrelevant parsing errors" do
        # malformed Received header
        foo = "Received: one two three; 5 Jun 2013 10:05:43 -0600\r\nTo: me+123-1@fake.fake\r\n\r\nfoo body"

        @mock_mailbox.expects(:connect)
        @mock_mailbox.expects(:move_message).never
        @mock_mailbox.expects(:delete_message).with(:foo)
        @mock_mailbox.expects(:each_message).yields(:foo, foo)
        @mock_mailbox.expects(:disconnect)
        imp = IncomingMessageProcessor.new(message_handler, error_reporter)
        imp.expects(:process_single).with(kind_of(Mail::Message), "123-1", anything)
        imp.process
      end

      it "should move aside messages that have relevant parsing errors" do
        foo = "To: me+123-1@fake.f\n ake\r\n\r\nfoo body" # illegal folding of "to" header

        @mock_mailbox.expects(:connect)
        @mock_mailbox.expects(:delete_message).never
        @mock_mailbox.expects(:move_message).with(:foo, 'errors_go_here')
        @mock_mailbox.expects(:each_message).yields(:foo, foo)
        @mock_mailbox.expects(:disconnect)
        error_reporter.expects(:log_error).
          with(IncomingMessageProcessor.error_report_category, kind_of(Hash))

        IncomingMessageProcessor.new(message_handler, error_reporter).process
      end

      it "should move aside messages that raise errors" do
        foo = "To: me+123-1@fake.fake\r\n\r\nfoo body"

        Mail.stubs(:new).raises(StandardError)

        @mock_mailbox.expects(:connect)
        @mock_mailbox.expects(:delete_message).never
        @mock_mailbox.expects(:move_message).with(:foo, 'errors_go_here')
        @mock_mailbox.expects(:each_message).yields(:foo, foo)
        @mock_mailbox.expects(:disconnect)
        error_reporter.expects(:log_exception).
          with(IncomingMessageProcessor.error_report_category, kind_of(StandardError), anything)

        IncomingMessageProcessor.new(message_handler, error_reporter).process
      end

      it "should abort account processing on exception, but continue processing other accounts" do
        IncomingMessageProcessor.configure({
          'imap' => {
            'error_folder' => 'errors_go_here',
            'accounts' => [
              {'username' => 'first'},
              {'username' => 'second'},
            ]
          }
        })

        seq = sequence('connect')
        @mock_mailbox.expects(:connect).in_sequence(seq).raises(StandardError)
        @mock_mailbox.expects(:connect).in_sequence(seq)
        @mock_mailbox.expects(:disconnect).in_sequence(seq)
        @mock_mailbox.expects(:each_message).once
        error_reporter.expects(:log_exception).
          with(IncomingMessageProcessor.error_report_category, kind_of(StandardError), anything)

        IncomingMessageProcessor.new(message_handler, error_reporter).process
      end
    end

    it "should accept multiple account types with overrides" do
      config = {
        'imap' => {
          'server' => 'fake',
          'accounts' => [
            {'username' => 'foo'},
            {'username' => 'bar'},
          ]
        },

        'directory' => {'folder' => '/tmp/mail'},
      }
      IncomingMessageProcessor.configure(config)
      accounts = IncomingMessageProcessor.mailbox_accounts
      accounts.size.should eql 3
      protocols = accounts.map(&:protocol)
      protocols.count.should eql 3
      protocols.count(:imap).should eql 2
      protocols.count(:directory).should eql 1
      usernames = accounts.map(&:config).map{ |c| c[:username] }
      usernames.count('foo').should eql 1
      usernames.count('bar').should eql 1
      usernames.count(nil).should eql 1
    end

    it "should not try to load messages with invalid address tag" do
      # this should be tested through the public "process" method
      # rather than calling the private "find_matching_to_address" directly
      account, message = [mock, mock]
      account.expects(:address).returns('user@example.com')
      message.expects(:to).returns(['user@example.com'])
      result = IncomingMessageProcessor.extract_address_tag(message, account)
      result.should == false
    end
  end

  describe "timeouts" do
    class TimeoutMailbox
      include IncomingMailProcessor::ConfigurableTimeout

      def initialize(config)
        @config = config
      end
    end

    before do
      IncomingMessageProcessor.stubs(:get_mailbox_class).returns(TimeoutMailbox)

      [:connect, :each_message, :delete_message, :move_message, :disconnect].each do |f|
        TimeoutMailbox.any_instance.stubs(f)
      end
    end

    it "should abort processing on timeout, but continue with next account" do
      IncomingMessageProcessor.configure({
        'imap' => {
          'accounts' => [
            {'username' => 'first'},
            {'username' => 'second'},
          ]
        }
      })
      processed_second = false

      TimeoutMailbox.send(:define_method, :each_message) do
        if @config[:username] == 'first'
          raise Timeout::Error
        else
          processed_second = true
        end
      end

      error_reporter.expects(:log_exception)
      IncomingMessageProcessor.new(message_handler, error_reporter).process
      processed_second.should be_true
    end
  end
end
