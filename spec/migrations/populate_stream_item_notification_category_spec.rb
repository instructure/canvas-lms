#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe DataFixup::PopulateStreamItemNotificationCategory do
  it "should populate notification_category" do
    course_with_student(:active_all => true)
    category = "TestImmediately"
    Notification.create(:name => 'Assignment Due Date Changed', :category => category)
    allow_any_instance_of(Assignment).to receive(:created_at).and_return(4.hours.ago)
    assignment_model(:course => @course)
    @assignment.update_attribute(:due_at, 1.week.from_now)

    item = StreamItem.where(:asset_type => "Message").last
    # should have auto-populated with new code now
    expect(item.notification_category).to eq category

    StreamItem.where(:id => item).update_all(:notification_category => nil)
    DataFixup::PopulateStreamItemNotificationCategory.run

    item.reload
    expect(item.notification_category).to eq category
  end
end
