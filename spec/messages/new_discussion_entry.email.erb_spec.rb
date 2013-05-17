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

describe 'new_discussion_entry.email' do
  before do
    discussion_topic_model
    @object = @topic.discussion_entries.create!(:user => user_model)
  end
  
  it "should render" do
    generate_message(:new_discussion_entry, :email, @object)
  end

  it "should use the custom From: setting" do
    @object.context.root_account.settings[:outgoing_email_default_name] = "Custom From"
    msg = generate_message(:new_discussion_entry, :email, @object)
    msg.save
    msg.from_name.should == "Custom From"
  end
end
