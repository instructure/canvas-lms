# frozen_string_literal: true

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

describe 'enrollment_registration' do
  before :once do
    @root_account = Account.create(name: 'My Root Account')
    @sub_account = Account.create(name:'My Sub-account', parent_account: @root_account)
    @user1 = user_factory
    course_with_student(:account => @sub_account, :user => @user1)
    @user1.workflow_state = 'creation_pending'
  end

  let(:asset) { @enrollment }
  let(:notification_name) { :enrollment_registration }

  include_examples "a message"

  it "displays account name as plain text and removes footer links" do
    include MessagesCommon
    Notification.find_or_create_by!(category: "Registration", name: notification_name)
    msg = generate_message(notification_name, :email, asset)
    # this means the account name is not enclosed in a link
    expect(msg.html_body).to include "participate in a class at My Root Account."
    expect(msg.html_body).not_to include "participate in a class at My Sub-account."
    expect(msg.html_body).not_to include "Update your notification settings"
    expect(msg.html_body).not_to include "Click here to view course page"
    expect(@message.body).not_to include 'To change or turn off email notifications,'
  end
end
