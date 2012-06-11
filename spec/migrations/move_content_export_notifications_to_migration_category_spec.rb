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

describe 'DataFixup::MoveContentExportNotificationsToMigrationCategory' do
  it "remove correct notification policies" do
    user(:active_user => true)

    @n1 = Notification.create!(:name => 'Content Export Finished', :category => 'Other')
    @n2 = Notification.create!(:name => 'Other Thing', :category => 'Other')
    @cc = @user.communication_channels.create(:path => "user1@example.com").tap{|cc| cc.confirm!}

    NotificationPolicy.create(:notification => @n1, :communication_channel => @cc, :frequency => "daily")
    NotificationPolicy.create(:notification => @n2, :communication_channel => @cc, :frequency => "daily")

    DataFixup::MoveContentExportNotificationsToMigrationCategory.run

    nps = NotificationPolicy.for(@user)
    nps.count.should == 1
    nps.first.notification.should == @n2
  end
end
