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

require File.expand_path('../../spec_helper.rb', File.dirname(__FILE__))

describe IncomingMail::ReplyToAddress do
  expect_secure_id = Canvas::Security.hmac_sha1("1000001")

  describe 'initialize' do
    it 'should persist the message argument' do
      expect(IncomingMail::ReplyToAddress.new("some message").message).to eq "some message"
    end
  end

  describe 'address' do
    it 'should return nil for SMS messages' do
      message = mock()
      message.expects(:path_type).returns('sms')

      expect(IncomingMail::ReplyToAddress.new(message).address).to be_nil
    end

    it 'should return the message from address for error reports' do
      message = mock()
      message.expects(:path_type).returns('email')
      message.expects(:context_type).returns('ErrorReport')
      message.expects(:from).returns('user@example.com')

      expect(IncomingMail::ReplyToAddress.new(message).address).to eq 'user@example.com'
    end

    it 'should generate a reply-to address for email messages' do
      message = mock()

      message.expects(:path_type).returns('email')
      message.expects(:context_type).returns('Course')
      message.expects(:id).twice.returns(1)
      message.expects(:global_id).twice.returns(1000001)
      IncomingMail::ReplyToAddress.address_pool = %w{canvas@example.com}

      expect(IncomingMail::ReplyToAddress.new(message).address).to eq "canvas+#{expect_secure_id}-1000001@example.com"
    end
  end

  describe 'secure_id' do
    it 'should generate a unique hash for the message' do
      message       = mock()
      message.expects(:global_id).returns(1000001)

      expect(IncomingMail::ReplyToAddress.new(message).secure_id).to eq expect_secure_id
    end
  end

  describe 'self.address_pool=' do
    it 'should persist an address pool' do
      pool = %w{canvas@example.com canvas2@example.com}
      IncomingMail::ReplyToAddress.address_pool = pool

      expect(IncomingMail::ReplyToAddress.instance_variable_get(:@address_pool)).to eq pool
    end
  end

  describe 'self.address_from_pool' do
    it 'should return an address from the pool in a deterministic way' do
      message, message2 = [mock(), mock()]

      message.expects(:id).twice.returns(14)
      message2.expects(:id).twice.returns(15)
      IncomingMail::ReplyToAddress.address_pool = %w{canvas@example.com canvas2@example.com}

      expect(IncomingMail::ReplyToAddress.address_from_pool(message)).to  eq 'canvas@example.com'
      expect(IncomingMail::ReplyToAddress.address_from_pool(message2)).to eq 'canvas2@example.com'
    end

    it 'should raise EmptyReplyAddressPool if pool is empty' do
      message = mock()
      IncomingMail::ReplyToAddress.address_pool = []

      expect {
        IncomingMail::ReplyToAddress.address_from_pool(message)
      }.to raise_error(IncomingMail::ReplyToAddress::EmptyReplyAddressPool)
    end

    it 'should randomly select a pool address if the message has no id' do
      message = mock()

      message.expects(:id).returns(nil)
      IncomingMail::ReplyToAddress.address_pool = %w{canvas@example.com}

      expect(IncomingMail::ReplyToAddress.address_from_pool(message)).to  eq 'canvas@example.com'
    end
  end
end
