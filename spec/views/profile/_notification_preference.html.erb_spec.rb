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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/profile/_notification_preference" do
  it "should render" do
    course_with_student
    view_context
    assigns[:user] = @user
    n = Notification.create!
    cc = @user.communication_channels.create!(:path => 'user@example.com')
    pref = cc.notification_policies.create!(:notification => n)
    assigns[:notification_preference] = pref
    assigns[:email_channels] = []
    assigns[:other_channels] = []

    render :partial => "profile/notification_preference", :object => n, :locals => {:list => [pref]}
    response.should_not be_nil
  end
end

