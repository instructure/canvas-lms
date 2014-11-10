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

    @n1 = Notification.create!(:name => 'Content Export Finished', :category => 'Other')
    @n2 = Notification.create!(:name => 'Other Thing', :category => 'Other')

    users = []
    3.times do |i|
      u = user(:active_user => true)
      cc = u.communication_channels.create(:path => "user#{i}@example.com").tap{|cc| cc.confirm!} 
      NotificationPolicy.create(:notification => @n1, :communication_channel => cc, :frequency => "daily")
      NotificationPolicy.create(:notification => @n2, :communication_channel => cc, :frequency => "daily")
      users << u
    end

    DataFixup::MoveContentExportNotificationsToMigrationCategory.run

    users.each do |u|
      nps = NotificationPolicy.for(u)
      expect(nps.count).to eq 1
      expect(nps.first.notification).to eq @n2
    end
  end
end
