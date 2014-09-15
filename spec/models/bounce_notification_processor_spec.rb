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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe BounceNotificationProcessor do
  before(:once) do
    bounce_queue_log = File.read(File.dirname(__FILE__) + '/../fixtures/bounces.json')
    @all_bounce_messages_json = JSON.parse(bounce_queue_log)
    @soft_bounce_messages_json = @all_bounce_messages_json.select {|m| m['Message'].include?('Transient')}
    @hard_bounce_messages_json = @all_bounce_messages_json.select {|m| m['Message'].include?('Permanent')}
  end

  def mock_message(json)
    message = mock
    message.stubs(:body).returns(json.to_json)
    message
  end

  describe ".process" do
    it "processes each notification in the queue" do
      bnp = BounceNotificationProcessor.new(access_key: 'key', secret_access_key: 'secret')
      queue = mock
      queue.expects(:poll).multiple_yields(*@all_bounce_messages_json.map {|m| mock_message(m)})
      bnp.stubs(:bounce_queue).returns(queue)
      bnp.expects(:process_bounce_notification).times(@all_bounce_messages_json.size)
      bnp.process
    end

    it "flags addresses with hard bounces" do
      bnp = BounceNotificationProcessor.new(access_key: 'key', secret_access_key: 'secret')
      queue = mock
      queue.expects(:poll).multiple_yields(*@all_bounce_messages_json.map {|m| mock_message(m)})
      bnp.stubs(:bounce_queue).returns(queue)

      CommunicationChannel.expects(:bounce_for_path).with('hard@example.edu').times(5)
      CommunicationChannel.expects(:bounce_for_path).with('suppressed@example.edu').times(1)
      CommunicationChannel.expects(:bounce_for_path).with('soft@example.edu').times(0)

      bnp.process
    end
  end
end
