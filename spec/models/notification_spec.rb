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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

## Helpers
def notification_set(opts = {})
  user_opts = opts.delete(:user_opts) || {}
  notification_opts = opts.delete(:notification_opts)  || {}

  assignment_model
  notification_model({:subject => "<%= t :subject, 'This is 5!' %>", :name => "Test Name"}.merge(notification_opts))
  user_model({:workflow_state => 'registered'}.merge(user_opts))
  communication_channel_model.confirm!
  notification_policy_model(:notification => @notification,
    :communication_channel => @communication_channel)

  @notification.reload
end

describe Notification do
  it "should create a new instance given valid attributes" do
    Notification.create!(notification_valid_attributes)
  end

  it "should have a default delay_for" do
    notification_model
    expect(@notification.delay_for).to be >= 0
  end

  it "should have a decent state machine" do
    notification_model
    expect(@notification.state).to eql(:active)
    @notification.deactivate
    expect(@notification.state).to eql(:inactive)
    @notification.reactivate
    expect(@notification.state).to eql(:active)
  end

  it "should always have some subject" do
    expect(Notification.create!(:name => 'Testing').subject).not_to be_nil
  end
end



