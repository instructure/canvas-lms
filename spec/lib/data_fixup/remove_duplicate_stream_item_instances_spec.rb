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

require 'spec_helper'
require 'db/migrate/20160212204337_remove_duplicate_stream_item_instances.rb'

describe DataFixup::RemoveDuplicateStreamItemInstances do
  it "should find and remove duplicates" do
    mig = RemoveDuplicateStreamItemInstances.new
    mig.down

    user = User.create!
    context = Course.create!
    dt = DiscussionTopic.create!(:context => context)
    dt.generate_stream_items([user])
    stream_item = user.stream_item_instances.first.stream_item
    StreamItemInstance.create!(context: stream_item.context, stream_item: stream_item, user: user)

    expect{mig.up}.to change{StreamItemInstance.count}.from(2).to(1)
  end
end
