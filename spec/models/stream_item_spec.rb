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

describe StreamItem do
  it "should not infer a user_id for DiscussionTopic" do
    user
    context = Course.create!
    dt = DiscussionTopic.create!(:context => context)
    dt.generate_stream_items([@user])
    si = @user.stream_item_instances.first.stream_item
    data = si.stream_data(@user.id)
    data.type.should == 'DiscussionTopic'
    data.user_id.should be_nil
  end
end
