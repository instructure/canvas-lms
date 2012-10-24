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
  before(:all) do
    DiscussionTopic.class_eval {
      alias_method :old_reply_from, :reply_from
      def reply_from(opts)
        @@incoming_replies ||= []
        @@incoming_replies << opts
        if @@reply_from_result.kind_of?(Class) && @@reply_from_result.ancestors.include?(Exception)
          raise @@reply_from_result
        else
          @@reply_from_result
        end
      end

      def self.reply_from_result
        @@reply_from_result
      end

      def self.reply_from_result=(value)
        @@reply_from_result = value
      end

      def self.incoming_replies
        @@incoming_replies
      end

      def self.incoming_replies=(replies)
        @@incoming_replies = replies
      end
    }
  end

  before(:each) do
    DiscussionTopic.incoming_replies = []
    DiscussionTopic.reply_from_result = DiscussionEntry.new

    discussion_topic_model
    @message = Message.create(:context => @topic, :user => @user)
    @previous_message_count = Message.count
    @previous_message_count.should == 1
  end

  after(:all) do
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
    it "should send a bounce reply when sent a bogus secure_id" do
      IncomingMessageProcessor.process_single(Mail.new { body "body"; from "a@b.c" }, 
        "deadbeef", @message.id)
      Message.count.should == @previous_message_count + 1
      # new_message = Message.find_by_id(@message.id + 1)
      new_message = Message.find(:first, :order => 'created_at DESC')
      new_message.subject.should match(/Reply Failed/)
      new_message.body.should match(/unknown mailbox/)
    end

    it "should send a bounce reply when sent a bogus message id" do
      IncomingMessageProcessor.process_single(Mail.new { body "body"; from "a@b.c" },
        @message.reply_to_secure_id, -1)
      Message.count.should == @previous_message_count + 1
      # new_message = Message.find_by_id(@message.id + 1)
      new_message = Message.find(:first, :order => 'created_at DESC')
      new_message.subject.should match(/Reply Failed/)
      new_message.body.should match(/unknown mailbox/)
    end

    it "should send a bounce reply when user is not found" do
      @message.user = nil
      @message.save!
      IncomingMessageProcessor.process_single(Mail.new { body "body"; from "a@b.c" }, 
        @message.reply_to_secure_id, @message.id)
      Message.count.should == @previous_message_count + 1
      # new_message = Message.find_by_id(@message.id + 1)
      new_message = Message.find(:first, :order => 'created_at DESC')
      new_message.subject.should match(/Reply Failed/)
      new_message.body.should match(/unknown mailbox/)
    end

    it "should send a bounce reply when context is not found" do
      @message.context = nil
      @message.save!
      IncomingMessageProcessor.process_single(Mail.new { body "body"; from "a@b.c" }, 
        @message.reply_to_secure_id, @message.id)
      Message.count.should == @previous_message_count + 1
      # new_message = Message.find_by_id(@message.id + 1)
      new_message = Message.find(:first, :order => 'created_at DESC')
      new_message.subject.should match(/Reply Failed/)
      new_message.body.should match(/unknown mailbox/)
    end
  end

  it "should send a bounce reply when reply_from raises ReplyToLockedTopicError" do
    DiscussionTopic.reply_from_result = IncomingMessageProcessor::ReplyToLockedTopicError
    test_mail = Mail.new { body "reply body"; from "test@example.a" }
    IncomingMessageProcessor.process_single(test_mail, @message.reply_to_secure_id, @message.id)
    Message.count.should == @previous_message_count + 1
    new_message = Message.find(:first, :order => 'created_at DESC')
    new_message.body.should match(/topic is locked/)
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
