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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe IncomingMail::IncomingMessageProcessor do

  # Import this one constant
  IncomingMessageProcessor = IncomingMail::IncomingMessageProcessor

  def setup_test_outgoing_mail
    @original_delivery_method = ActionMailer::Base.delivery_method
    @original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
  end

  def restore_original_outgoing_mail
    ActionMailer::Base.delivery_method = @original_delivery_method if @original_delivery_method
    ActionMailer::Base.perform_deliveries = @original_perform_deliveries if @original_perform_deliveries
  end

  def simple_mail_from_user
    Mail.new(:body => "body", :from => @user.email_channel.path)
  end

  def check_new_message(bounce_type)
    Message.count.should == @previous_message_count + 1
    @new_message = Message.order("created_at DESC, id DESC").first
    @new_message.subject.should match(/Reply Failed/)
    @new_message.body.should match(case bounce_type
      when :unknown then /unknown mailbox/
      when :locked then /topic is locked/
      end)
    # new checks to make sure these messages are getting sent
    @new_message.user_id.should == @user.id
    @new_message.communication_channel_id.should == @user.email_channel.id
    @new_message.should be_sent
  end

  let(:message_handler) { MockMessageHandler.new }

  class MockMessageHandler
    attr_reader :account, :body, :html_body, :incoming_message, :tag

    def handle(account, body, html_body, incoming_message, tag)
      @account = account
      @body = body
      @html_body = html_body
      @incoming_message = incoming_message
      @tag = tag
    end
  end

  let(:tag) { '123abc' }

  before(:all) do
    setup_test_outgoing_mail

    DiscussionTopic.class_eval {
      alias_method :old_reply_from, :reply_from
      def reply_from(opts)
        DiscussionTopic.incoming_replies ||= []
        DiscussionTopic.incoming_replies << opts
        result = DiscussionTopic.reply_from_result
        if result.kind_of?(Class) && result.ancestors.include?(Exception)
          raise result
        else
          result
        end
      end

      def self.reply_from_result
        @reply_from_result
      end

      def self.reply_from_result=(value)
        @reply_from_result = value
      end

      def self.incoming_replies
        @incoming_replies
      end

      def self.incoming_replies=(replies)
        @incoming_replies = replies
      end
    }
  end

  before(:each) do
    ErrorReport.expects(:log_exception).never
    ErrorReport.expects(:log_error).never
  end

  after(:all) do
    restore_original_outgoing_mail
    DiscussionTopic.class_eval { alias_method :reply_from, :old_reply_from }
  end

  describe ".configure" do
    it "should raise on invalid configuration settings" do
      expect { IncomingMessageProcessor.configure('bogus_setting' => 42) }.to raise_error(StandardError)
    end

    it "should accept legacy mailman configurations" do
      IncomingMessageProcessor.configure('poll_interval' => 42, 'ignore_stdin' => true)
    end
  end

  describe ".run_periodically?" do
    it "should consult .poll_interval and .ignore_stdin for backwards compatibility" do
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
    before(:each) do
      @notification = Notification.create!
      @message = Message.create(:context => @topic, :user => @user, :notification => @notification)
    end

    it "should not choke on invalid UTF-8" do
      IncomingMessageProcessor.new(message_handler).process_single(Mail.new { body "he\xffllo" }, tag)

      message_handler.body.should == "hello"
      message_handler.html_body.should == "hello"
    end

    it "should convert another charset to UTF-8" do
      IncomingMessageProcessor.new(message_handler).process_single(Mail.new {
          content_type 'text/plain; charset=Shift-JIS'
          body "\x83\x40"
        }, tag)

      comparison_string = "\xe3\x82\xa1"
      comparison_string.force_encoding("UTF-8")
      message_handler.body.should == comparison_string
      message_handler.html_body.should == comparison_string
    end

    it "should pick up html from a multipart" do
      IncomingMessageProcessor.new(message_handler).process_single(Mail.new {
          text_part do
            body 'This is plain text'
          end
          html_part do
            content_type 'text/html; charset=UTF-8'
            body '<h1>This is HTML</h1>'
          end
        }, tag)
      message_handler.body.should == 'This is plain text'
      message_handler.html_body.should == '<h1>This is HTML</h1>'
    end

    it "should not send a bounce reply when the incoming message is an auto-response" do
      user_model
      @cc = @user.communication_channels.build(:path_type => 'email', :path => "user@example.com")
      @cc.confirm
      @cc.save!
      @message.context = nil # potentially bounce
      @message.save!
      incoming_bounce_mail = simple_mail_from_user
      incoming_bounce_mail['Auto-Submitted'] = 'auto-generated' # but don't bounce with this header

      message_handler.expects(:handle).never

      IncomingMessageProcessor.new(message_handler).process_single(incoming_bounce_mail,
        tag)
    end
  end

  describe "#process" do
    before(:each) do
      @mock_mailbox = mock
      IncomingMessageProcessor.stubs(:create_mailbox => @mock_mailbox)
    end

    it "should support original incoming_mail configuration format for a single inbox" do
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
      IncomingMessageProcessor.new(message_handler).process
    end

    it "should process incoming_mail configuration with multiple accounts" do
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
      IncomingMessageProcessor.new(message_handler).process
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

      IncomingMail::MailboxAccount.expects(:new).with({
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
        imp = IncomingMessageProcessor.new(message_handler)
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
        imp = IncomingMessageProcessor.new(message_handler)
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
        ErrorReport.expects(:log_error).
          with(IncomingMessageProcessor.error_report_category, kind_of(Hash))

        IncomingMessageProcessor.new(message_handler).process
      end

      it "should move aside messages that raise errors" do
        foo = "To: me+123-1@fake.fake\r\n\r\nfoo body"

        Mail.stubs(:new).raises(StandardError)

        @mock_mailbox.expects(:connect)
        @mock_mailbox.expects(:delete_message).never
        @mock_mailbox.expects(:move_message).with(:foo, 'errors_go_here')
        @mock_mailbox.expects(:each_message).yields(:foo, foo)
        @mock_mailbox.expects(:disconnect)
        ErrorReport.expects(:log_exception).
          with(IncomingMessageProcessor.error_report_category, kind_of(StandardError), anything)

        IncomingMessageProcessor.new(message_handler).process
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
        ErrorReport.expects(:log_exception).
          with(IncomingMessageProcessor.error_report_category, kind_of(StandardError), anything)

        IncomingMessageProcessor.new(message_handler).process
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

    it "should not try to load messages with invalid address tags" do
      # this should be tested through the public "process" method
      # rather than calling the private "extract_address_tag" directly
      account, message = [mock, mock]
      account.expects(:address).returns('user@example.com')
      message.expects(:to).returns(['user@example.com'])
      result = IncomingMessageProcessor.extract_address_tag(message, account)
      result.should == false
    end
  end

  describe "timeouts" do
    class TimeoutMailbox
      include IncomingMail::ConfigurableTimeout

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

      ErrorReport.expects(:log_exception)
      IncomingMessageProcessor.new(message_handler).process
      processed_second.should be_true
    end
  end
end
