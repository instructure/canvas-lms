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

describe IncomingMailProcessor::Pop3Mailbox do
  include_examples 'Mailbox'

  def default_config
    {
      :server => "mail.example.com",
      :ssl => false,
      :port => 2345,
      :username => "user",
      :password => "password",
    }
  end

  def mock_net_pop
    @pop_mock = Object.new
    class <<@pop_mock
      IncomingMailProcessor::Pop3Mailbox::UsedPopMethods.each do |method_name|
        define_method(method_name) { |*args, &block| }
      end
    end

    Net::POP3.stubs(:new).returns(@pop_mock)
  end

  describe "#initialize" do
    it "should accept existing mailman pop3 configuration" do
      @mailbox = IncomingMailProcessor::Pop3Mailbox.new({
        :server => "pop3.server.com",
        :port => 1234,
        :ssl => "truthy-value",
        :username => "user@server.com",
        :password => "secret-user-password",
      })

      @mailbox.server.should eql "pop3.server.com"
      @mailbox.port.should eql 1234
      @mailbox.ssl.should eql "truthy-value"
      @mailbox.username.should eql "user@server.com"
      @mailbox.password.should eql "secret-user-password"
    end
  end

  describe "#connect" do
    before do
      mock_net_pop
    end

    it "should connect to the server" do
      config = default_config.merge(:ssl => false, :port => 110)
      Net::POP3.expects(:new).with(config[:server], config[:port]).returns(@pop_mock)
      @pop_mock.expects(:start).with(config[:username], config[:password])

      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(config)
      @mailbox.connect
    end

    it "should use ssl if configured" do
      config = default_config.merge(:ssl => true, :port => 995)

      Net::POP3.expects(:new).with(config[:server], config[:port]).returns(@pop_mock)
      @pop_mock.expects(:enable_ssl).with(OpenSSL::SSL::VERIFY_NONE)
      @pop_mock.expects(:start).with(config[:username], config[:password])

      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(config)
      @mailbox.connect
    end
  end

  describe "#disconnect" do
    it "should disconnect" do
      mock_net_pop
      @pop_mock.expects(:finish)

      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(default_config)
      @mailbox.connect
      @mailbox.disconnect
    end
  end

  describe "#each_message" do
    before do
      mock_net_pop
      @mailbox = IncomingMailProcessor::Pop3Mailbox.new(default_config)
      @mailbox.connect
    end

    def mock_pop_mail(body)
      result = mock(:pop => body)
    end

    it "should retrieve and yield messages" do
      foo = mock_pop_mail("foo body")
      bar = mock_pop_mail("bar body")
      baz = mock_pop_mail("baz body")
      @pop_mock.expects(:mails).returns([foo, bar, baz])

      yielded_values = []
      @mailbox.each_message do |message_id, body|
        yielded_values << [message_id, body]
      end

      yielded_values.should eql [[foo, "foo body"], [bar, "bar body"], [baz, "baz body"]]
    end

    context "with simple foo message" do
      before do
        @foo = mock_pop_mail("foo body")
        @pop_mock.expects(:mails).returns([@foo])
      end

      it "should delete when asked" do
        @foo.expects(:delete)
        @mailbox.each_message do |message_id, body|
          @mailbox.delete_message(message_id)
        end
      end

      it "should delete when asked to move" do
        @foo.expects(:delete)
        @mailbox.each_message do |message_id, body|
          @mailbox.move_message(message_id, "anything")
        end
      end
    end
  end

end
