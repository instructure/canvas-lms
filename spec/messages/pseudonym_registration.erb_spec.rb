#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'pseudonym_registration' do
  before :once do
    pseudonym_model
  end

  let(:asset) { @pseudonym }
  let(:message_data) do
    { user: @user }
  end
  let(:notification_name) { :pseudonym_registration }

  include_examples "a message"

  it "removes profile url link" do
    include MessagesCommon
    msg = generate_message(notification_name, :email, asset, message_data)
    expect(msg.html_body).to include "for a Canvas account at Default Account!"
    expect(msg.html_body).not_to include "Update your notification settings"
  end
end
