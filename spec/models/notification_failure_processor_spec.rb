#
# Copyright (C) 2016 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../messages/messages_helper')

describe NotificationFailureProcessor do
  before(:once) do
    user_model
    @au = tie_user_to_account(@user, account: account_model)
    @message = generate_message(:account_user_notification, :email, @au, user: @user)

    @failure_messages = [
      {
        global_id: 5000,
        error: 'Error from mail system'
      },
      {
        global_id: 5001,
        error: 'Error from SNS system'
      }
    ]
  end

  def mock_message(obj)
    message = mock
    message.stubs(:body).returns(obj.to_json)
    message
  end

  def mock_queue
    queue = mock
    queue.expects(:poll).multiple_yields(*@failure_messages.map { |m| mock_message(m) })
    queue
  end

  describe '.process' do
    it 'puts message into error state' do
      expect(@message.state).to_not eq(:error)
      expect(@message.transmission_errors).to be_blank
      nfp = NotificationFailureProcessor.new(access_key: 'key', secret_access_key: 'secret')
      nfp.stubs(:global_message).returns(@message)
      nfp.stubs(:notification_failure_queue).returns(mock_queue)
      nfp.process
      expect(@message.state).to eq(:transmission_error)
      expect(@message.transmission_errors).to_not be_blank
    end
  end
end