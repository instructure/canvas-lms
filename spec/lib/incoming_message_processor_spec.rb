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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe IncomingMessageProcessor do
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
    @new_message = Message.find(:first, :order => 'created_at DESC')
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
    DiscussionTopic.incoming_replies = []
    DiscussionTopic.reply_from_result = DiscussionEntry.new

    discussion_topic_model
    @cc = @user.communication_channels.build(:path_type => 'email', :path => "user@example.com")
    @cc.confirm
    @cc.save!
    @notification = Notification.create!
    @message = Message.create(:context => @topic, :user => @user, :notification => @notification)
    @previous_message_count = Message.count
    @previous_message_count.should == 1
  end

  after(:all) do
    restore_original_outgoing_mail
    DiscussionTopic.class_eval { alias_method :reply_from, :old_reply_from }
  end

  it "should not choke on invalid UTF-8" do
    IncomingMessageProcessor.process_single(Mail.new { body "he\xffllo" }, @message.reply_to_secure_id, @message.id)
    DiscussionTopic.incoming_replies.length.should == 1
    DiscussionTopic.incoming_replies[0][:text].should == 'hello'
    DiscussionTopic.incoming_replies[0][:html].should == 'hello'
  end

  it "should convert another charset to UTF-8" do
    IncomingMessageProcessor.process_single(Mail.new {
        content_type 'text/plain; charset=Shift-JIS'
        body "\x83\x40"
      }, @message.reply_to_secure_id, @message.id)
    DiscussionTopic.incoming_replies.length.should == 1
    comparison_string = "\xe3\x82\xa1"
    comparison_string.force_encoding("UTF-8") if RUBY_VERSION >= '1.9'
    DiscussionTopic.incoming_replies[0][:text].should == comparison_string
    DiscussionTopic.incoming_replies[0][:html].should == comparison_string
  end

  it "should pick up html from a multipart" do
    IncomingMessageProcessor.process_single(Mail.new {
        text_part do
          body 'This is plain text'
        end
        html_part do
          content_type 'text/html; charset=UTF-8'
          body '<h1>This is HTML</h1>'
        end
      }, @message.reply_to_secure_id, @message.id)
    DiscussionTopic.incoming_replies.length.should == 1
    DiscussionTopic.incoming_replies[0][:text].should == 'This is plain text'
    DiscussionTopic.incoming_replies[0][:html].should == '<h1>This is HTML</h1>'
  end

  describe "when data is not found" do
    it "should not send a bounce reply sent a bogus message id" do
      expect {
        IncomingMessageProcessor.process_single(simple_mail_from_user,
          @message.reply_to_secure_id, -1)
      }.to change { ActionMailer::Base.deliveries.size }.by(0)
      Message.count.should eql @previous_message_count
    end

    it "should not send a bounce reply when sent a bogus secure_id" do
      expect {
        IncomingMessageProcessor.process_single(simple_mail_from_user,
          "deadbeef", @message.id)
      }.to change { ActionMailer::Base.deliveries.size }.by(0)
      Message.count.should eql @previous_message_count
    end

    it "should not send a bounce reply when the original message does not have a notification" do
      @message.context = nil # potentially bounce
      @message.notification = nil # but don't bounce this
      @message.save!
      expect {
        IncomingMessageProcessor.process_single(simple_mail_from_user,
          @message.reply_to_secure_id, @message.id)
      }.to change { ActionMailer::Base.deliveries.size }.by(0)
      Message.count.should eql @previous_message_count
    end

    it "should not send a bounce reply when the incoming message is an auto-response" do
      @message.context = nil # potentially bounce
      @message.save!
      incoming_bounce_mail = simple_mail_from_user
      incoming_bounce_mail['Auto-Submitted'] = 'auto-generated' # but don't bounce with this header
      expect {
        IncomingMessageProcessor.process_single(incoming_bounce_mail,
          @message.reply_to_secure_id, @message.id)
      }.to change { ActionMailer::Base.deliveries.size }.by(0)
      Message.count.should eql @previous_message_count
    end

    it "should send a bounce reply when user is not found" do
      @message.user = nil
      @message.save!
      IncomingMessageProcessor.process_single(simple_mail_from_user, 
        @message.reply_to_secure_id, @message.id)
      check_new_message(:unknown)
    end

    it "should send a bounce reply when context is not found" do
      @message.context = nil
      @message.save!
      IncomingMessageProcessor.process_single(simple_mail_from_user, 
        @message.reply_to_secure_id, @message.id)
      check_new_message(:unknown)
    end

    it "should send a bounce reply directly if no communication channel is found" do
      @message.context = nil # to make it bounce
      @message.save!
      expect {
        IncomingMessageProcessor.process_single(Mail.new(:body => "body", :from => "bogus_email@example.com"),
        @message.reply_to_secure_id, @message.id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
      Message.count.should eql @previous_message_count
    end
  end

  it "should send a bounce reply when reply_from raises ReplyToLockedTopicError" do
    DiscussionTopic.reply_from_result = IncomingMessageProcessor::ReplyToLockedTopicError
    IncomingMessageProcessor.process_single(simple_mail_from_user, 
      @message.reply_to_secure_id, @message.id)
    check_new_message(:locked)
  end

  it "should process emails from mailman" do
    Dir.mktmpdir do |tmpdir|
      newdir = tmpdir + "/new"
      Dir.mkdir(newdir)
      
      addr, domain = HostUrl.outgoing_email_address.split(/@/)
      to_address = "#{addr}+#{@message.reply_to_secure_id}-#{@message.id}@#{domain}"
      mail = Mail.new do
        from 'test@example.com'
        to to_address
        subject 'subject of test message'
        body 'body of test message'
      end
      
      Mailman.config.maildir = nil
      Mailman.config.ignore_stdin = false
      Mailman.config.poll_interval = 0
      Mailman.config.pop3 = nil
      
      # If we try to use maildir with mailman, it will just poll the maildir forever.
      # Using stdin is the safest, but we have to do this little dance for it to work.
      read, write = IO.pipe
      saved_stdin = STDIN.dup
      write.puts mail.to_s
      write.close
      STDIN.reopen(read)
      IncomingMessageProcessor.process
      STDIN.reopen(saved_stdin)
      
      DiscussionTopic.incoming_replies.length.should == 1
      DiscussionTopic.incoming_replies[0][:text].should == 'body of test message'
    end
  end
end
