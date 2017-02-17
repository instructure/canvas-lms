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
MAIL_FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/'

RSpec::Matchers.define :imap_account_with_creds do |user, pass|
  match do |account|
    account.protocol == :imap &&
      account.config == { :server => 'fake', :username => user, :password => pass }
  end
end
RSpec::Matchers.define :imap_account_with_config do |config|
  match do |account|
    account.protocol == :imap && account.config == config
  end
end

describe IncomingMailProcessor::IncomingMessageProcessor do

  # Import this one constant
  IncomingMessageProcessor = IncomingMailProcessor::IncomingMessageProcessor

  let(:logger) { double('logger').tap{|l| expect(l).to receive(:warn).at_least(1).with(kind_of(String))} }
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

  def get_fixture (name)
    mail = Mail.read(MAIL_FIXTURES_PATH + name)
    return mail
  end


  def get_expected_text (name)
    file = File.open(MAIL_FIXTURES_PATH + 'expected/' + name + '.text_body', 'rb')
    content = file.read
    file.close

    return content
  end

  def get_expected_html (name)
    file = File.open(MAIL_FIXTURES_PATH + 'expected/' + name + '.html_body', 'rb')
    content = file.read
    file.close

    return content
  end

  def test_message (filename)
    message = get_processed_message(filename)

    text_body =  message.body.strip
    expect(text_body).to eq(get_expected_text(filename).strip)

    html_body =  message.html_body.strip
    expect(html_body).to eq(get_expected_html(filename).strip)
  end

  def get_processed_message(name)
    processor = IncomingMessageProcessor.new(message_handler, error_reporter)
    message = get_fixture(name)
    processor.process_single(message, '')

    return message_handler
  end

  let(:error_reporter) { MockErrorReporter.new }

  class MockErrorReporter
    def log_error(category, opts)
    end

    def log_exception(category, exception, opts)
    end
  end

  def expect_no_errors
    expect(error_reporter).to receive(:log_exception).never
    expect(error_reporter).to receive(:log_error).never
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
      expect(IncomingMessageProcessor.run_periodically?).to be_truthy

      IncomingMessageProcessor.configure('poll_interval' => 0, 'ignore_stdin' => false)
      expect(IncomingMessageProcessor.run_periodically?).to be_falsey

      IncomingMessageProcessor.configure('poll_interval' => 42, 'ignore_stdin' => true)
      expect(IncomingMessageProcessor.run_periodically?).to be_falsey
    end

    it "should use 'run_periodically' configuration setting" do
      IncomingMessageProcessor.configure({})
      expect(IncomingMessageProcessor.run_periodically?).to be_falsey

      IncomingMessageProcessor.configure('run_periodically' => true)
      expect(IncomingMessageProcessor.run_periodically?).to be_truthy
    end
  end

  describe "#process_single" do
    before do
      expect_no_errors
    end

    it "should not choke on invalid UTF-8" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new {
          content_type 'text/plain; charset=UTF-8'
          body "he\xffllo".force_encoding(Encoding::BINARY) }, '')

      expect(message_handler.body).to eq("hello")
      expect(message_handler.html_body).to eq("hello")
    end

    it "should convert another charset to UTF-8" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new {
          content_type 'text/plain; charset=Shift-JIS'
          body "\x83\x40".force_encoding(Encoding::BINARY)
        }, '')

      comparison_string = "\xe3\x82\xa1"
      comparison_string.force_encoding("UTF-8")
      expect(message_handler.body).to eq(comparison_string)
      expect(message_handler.html_body).to eq(comparison_string)
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
      expect(message_handler.body).to eq('This is plain text')
      expect(message_handler.html_body).to eq('<h1>This is HTML</h1>')
    end

    it "should not send a bounce reply when the incoming message is an auto-response" do
      incoming_bounce_message = Mail.new
      incoming_bounce_message['Auto-Submitted'] = 'auto-generated' # but don't bounce with this header

      expect(message_handler).to receive(:handle).never

      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(incoming_bounce_message, '')
    end

    it "creates text body from html only messages" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new {
          content_type 'text/html; charset=UTF-8'
          body '<h1>This is HTML</h1>'
        }, '')
      expect(message_handler.body).to eq("************\nThis is HTML\n************")
      expect(message_handler.html_body).to eq('<h1>This is HTML</h1>')
    end

    it "creates missing text part from html part" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new {
          html_part do
            content_type 'text/html; charset=UTF-8'
            body '<h1>This is HTML</h1>'
          end
        }, '')
      expect(message_handler.body).to eq("************\nThis is HTML\n************")
      expect(message_handler.html_body).to eq('<h1>This is HTML</h1>')
    end

    it "works with multipart emails with no html part" do
      test_message('multipart_mixed_no_html_part.eml')
    end

    it "should be able to extract text and html bodies from nested_multipart_sample.eml" do
      test_message('nested_multipart_sample.eml')
    end

    it "should be able to extract text and html bodies from multipart_mixed.eml" do
      test_message('multipart_mixed.eml')
    end

    it "should be able to extract text and html bodies from no_image.eml" do
      message = test_message('no_image.eml')
    end

    it "assumes text/plain when no content-type header is present" do
      IncomingMessageProcessor.new(message_handler, error_reporter).process_single(Mail.new {
          content_type nil
          body "hello" }, '')

      expect(message_handler.body).to eq("hello")
      expect(message_handler.html_body).to eq("hello")
    end

    context "reporting stats" do
      let (:message) { Mail.new(content_type: 'text/plain; charset=UTF-8', body: "hello") }

      it "increments the processed count" do
        expect(CanvasStatsd::Statsd).to receive(:increment).with("incoming_mail_processor.incoming_message_processed.").once
        IncomingMessageProcessor.new(message_handler, error_reporter).process_single(message, '')
      end

      it "reports the age based on the date header" do
        Timecop.freeze do
          message.date = 10.minutes.ago
          expect(CanvasStatsd::Statsd).to receive(:timing).once.with("incoming_mail_processor.message_age.", 10*60*1000)
          IncomingMessageProcessor.new(message_handler, error_reporter).process_single(message, '')
        end
      end

      it "does not report the age if there is no date header" do
        expect(CanvasStatsd::Statsd).to receive(:timing).never
        IncomingMessageProcessor.new(message_handler, error_reporter).process_single(message, '')
      end
    end
  end

  describe "#process" do
    before(:each) do
      @mock_mailbox = double
      allow(IncomingMessageProcessor).to receive(:create_mailbox).and_return(@mock_mailbox)
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

      imp = IncomingMessageProcessor
      expect(imp).to receive(:create_mailbox).with(imap_account_with_config(config['imap'].symbolize_keys)).
        and_return(@mock_mailbox).ordered
      IncomingMessageProcessor.configure(config)

      expect(@mock_mailbox).to receive(:connect)
      expect(@mock_mailbox).to receive(:each_message)
      expect(@mock_mailbox).to receive(:disconnect)
      expect_no_errors
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

      imp = IncomingMessageProcessor
      expect(imp).to receive(:create_mailbox).with(imap_account_with_creds('user1@fake.fake', 'pass1')).
        and_return(@mock_mailbox).ordered
      expect(imp).to receive(:create_mailbox).with(imap_account_with_creds('user2@fake.fake', 'pass2')).
        and_return(@mock_mailbox).ordered
      expect(imp).to receive(:create_mailbox).with(imap_account_with_creds('user3@fake.fake', 'pass3')).
        and_return(@mock_mailbox).ordered

      expect(@mock_mailbox).to receive(:connect).exactly(3).times
      expect(@mock_mailbox).to receive(:each_message).exactly(3).times
      expect(@mock_mailbox).to receive(:disconnect).exactly(3).times
      expect_no_errors

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

      expect(IncomingMailProcessor::MailboxAccount).to receive(:new).with({
        :protocol => :imap,
        :address => 'user@fake.fake',
        :error_folder => 'broken',
        :config => config['imap'].except('error_folder').symbolize_keys,
      })
      IncomingMessageProcessor.configure(config)
    end

    it "splits messages between multiple workers" do
      IncomingMessageProcessor.configure({
        'workers' => 3,
        'imap' => {
          'username' => 'user@example.com',
        }
      })
      expect(@mock_mailbox).to receive(:connect)
      expect(@mock_mailbox).to receive(:each_message).with({stride: 3, offset: 0})
      expect(@mock_mailbox).to receive(:disconnect)
      expect_no_errors
      imp = IncomingMessageProcessor.new(message_handler, error_reporter)
      imp.process(worker_id: 0)
      expect(@mock_mailbox).to receive(:connect)
      expect(@mock_mailbox).to receive(:each_message).with({stride: 3, offset: 1})
      expect(@mock_mailbox).to receive(:disconnect)
      imp.process(worker_id: 1)
      expect(@mock_mailbox).to receive(:connect)
      expect(@mock_mailbox).to receive(:each_message).with({stride: 3, offset: 2})
      expect(@mock_mailbox).to receive(:disconnect)
      imp.process(worker_id: 2)
    end

    it "only processes a single account if asked to do so" do
      IncomingMessageProcessor.configure({
        'imap' => {
          'server' => "fake",
          'username' => 'should_be_overridden@fake.fake',
          'accounts' => [
            { 'username' => 'user1@fake.fake', 'password' => 'pass1' },
            { 'username' => 'user2@fake.fake', 'password' => 'pass2' },
            { 'username' => 'user3@fake.fake', 'password' => 'pass3' },
          ],
        },
      })

      imp = IncomingMessageProcessor
      expect(imp).to receive(:create_mailbox).with(imap_account_with_creds('user2@fake.fake', 'pass2')).
        and_return(@mock_mailbox).ordered

      expect(@mock_mailbox).to receive(:connect)
      expect(@mock_mailbox).to receive(:each_message)
      expect(@mock_mailbox).to receive(:disconnect)
      expect_no_errors

      IncomingMessageProcessor.new(message_handler, error_reporter).process(:mailbox_account_address => 'user2@fake.fake')
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

        expect(@mock_mailbox).to receive(:connect)
        expect(@mock_mailbox).to receive(:move_message).never
        expect(@mock_mailbox).to receive(:delete_message).with(:foo)
        expect(@mock_mailbox).to receive(:delete_message).with(:bar)
        expect(@mock_mailbox).to receive(:delete_message).with(:baz)
        expect(@mock_mailbox).to receive(:each_message).and_yield(:foo, foo).and_yield(:bar, bar).and_yield(:baz, baz)
        expect(@mock_mailbox).to receive(:disconnect)

        imp = IncomingMessageProcessor.new(message_handler, error_reporter)
        expect(imp).to receive(:process_single).with(kind_of(Mail::Message), "123-1", anything)
        expect(imp).to receive(:process_single).with(kind_of(Mail::Message), "456-2", anything)
        expect(imp).to receive(:process_single).with(kind_of(Mail::Message), "abc-3", anything)
        expect_no_errors

        imp.process
      end

      it "should process messages that have irrelevant parsing errors" do
        # malformed Received header
        foo = "Received: one two three; 5 Jun 2013 10:05:43 -0600\r\nTo: me+123-1@fake.fake\r\n\r\nfoo body"

        expect(@mock_mailbox).to receive(:connect)
        expect(@mock_mailbox).to receive(:move_message).never
        expect(@mock_mailbox).to receive(:delete_message).with(:foo)
        expect(@mock_mailbox).to receive(:each_message).and_yield(:foo, foo)
        expect(@mock_mailbox).to receive(:disconnect)

        imp = IncomingMessageProcessor.new(message_handler, error_reporter)
        expect(imp).to receive(:process_single).with(kind_of(Mail::Message), "123-1", anything)
        expect_no_errors

        imp.process
      end

      it "should move aside messages that have relevant parsing errors" do
        foo = "To: me+123-1@fake.f\n ake\r\n\r\nfoo body" # illegal folding of "to" header

        expect(@mock_mailbox).to receive(:connect)
        expect(@mock_mailbox).to receive(:delete_message).never
        expect(@mock_mailbox).to receive(:move_message).with(:foo, 'errors_go_here')
        expect(@mock_mailbox).to receive(:each_message).and_yield(:foo, foo)
        expect(@mock_mailbox).to receive(:disconnect)
        expect(error_reporter).to receive(:log_error).
          with(IncomingMessageProcessor.error_report_category, kind_of(Hash))

        IncomingMessageProcessor.new(message_handler, error_reporter).process
      end

      it "should move aside messages that raise errors" do
        foo = "To: me+123-1@fake.fake\r\n\r\nfoo body"

        allow(Mail).to receive(:new).and_raise(StandardError)

        expect(@mock_mailbox).to receive(:connect)
        expect(@mock_mailbox).to receive(:delete_message).never
        expect(@mock_mailbox).to receive(:move_message).with(:foo, 'errors_go_here')
        expect(@mock_mailbox).to receive(:each_message).and_yield(:foo, foo)
        expect(@mock_mailbox).to receive(:disconnect)
        expect(error_reporter).to receive(:log_exception).
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

        expect(@mock_mailbox).to receive(:connect).and_raise(StandardError).ordered
        expect(@mock_mailbox).to receive(:connect).ordered
        expect(@mock_mailbox).to receive(:disconnect).ordered
        expect(@mock_mailbox).to receive(:each_message).once
        expect(error_reporter).to receive(:log_exception).
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
      expect(accounts.size).to eql 3
      protocols = accounts.map(&:protocol)
      expect(protocols.count).to eql 3
      expect(protocols.count(:imap)).to eql 2
      expect(protocols.count(:directory)).to eql 1
      usernames = accounts.map(&:config).map{ |c| c[:username] }
      expect(usernames.count('foo')).to eql 1
      expect(usernames.count('bar')).to eql 1
      expect(usernames.count(nil)).to eql 1
    end

    it "should not try to load messages with invalid address tag" do
      # this should be tested through the public "process" method
      # rather than calling the private "find_matching_to_address" directly
      account, message = [double, double]
      expect(account).to receive(:address).and_return('user@example.com')
      expect(message).to receive(:to).and_return(['user@example.com'])
      result = IncomingMessageProcessor.extract_address_tag(message, account)
      expect(result).to eq(false)
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
      allow(IncomingMessageProcessor).to receive(:get_mailbox_class).and_return(TimeoutMailbox)

      [:connect, :each_message, :delete_message, :move_message, :disconnect].each do |f|
        allow_any_instance_of(TimeoutMailbox).to receive(f)
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

      TimeoutMailbox.send(:define_method, :each_message) do |opts|
        if @config[:username] == 'first'
          raise Timeout::Error
        else
          processed_second = true
        end
      end

      err = MockErrorReporter.new
      expect(err).to receive(:log_exception).once
      IncomingMessageProcessor.new(message_handler, err).process
      expect(processed_second).to be_truthy
    end
  end
end
