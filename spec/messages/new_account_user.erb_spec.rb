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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'new_account_user' do
  before :once do
    account = Account.create!(:name => "some account", :settings => {:outgoing_email_default_name => "Custom From"})
    user_model
    @account_user = account.account_users.create!(user: @user)
  end

  let(:notification_name) { :new_account_user }
  let(:asset) { @account_user }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }

    it "should use the custom From: setting" do
      msg = generate_message(notification_name, path_type, asset)
      msg.save
      expect(msg.from_name).to eq "Custom From"
    end
  end
end