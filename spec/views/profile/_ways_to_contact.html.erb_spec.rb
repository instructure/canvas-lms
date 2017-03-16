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

describe "/profile/_ways_to_contact" do
  it "should render" do
    course_with_student
    view_context
    assign(:email_channels, [])
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render :partial => "profile/ways_to_contact"
    expect(response).not_to be_nil
  end

  it "should not show a student the confirm link" do
    course_with_student
    view_context
    @user.communication_channels.create!(:path_type => 'email', :path => 'someone@somewhere.com')
    expect(@user.communication_channels.first.state).to eq :unconfirmed
    assign(:email_channels, @user.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render :partial => "profile/ways_to_contact"
    expect(response.body).not_to match /confirm_channel_link/
  end

  it "should show an admin the confirm link" do
    account_admin_user
    view_context
    @user.communication_channels.create!(:path_type => 'email', :path => 'someone@somewhere.com')
    expect(@user.communication_channels.first.state).to eq :unconfirmed
    assign(:email_channels, @user.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render :partial => "profile/ways_to_contact"
    expect(response.body).to match /confirm_channel_link/
  end

  it "should not show confirm link for confirmed channels" do
    account_admin_user
    view_context
    @user.communication_channels.create!(:path_type => 'email', :path => 'someone@somewhere.com')
    @user.communication_channels.first.confirm
    expect(@user.communication_channels.first.state).to eq :active
    assign(:email_channels, @user.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render :partial => "profile/ways_to_contact"
    expect(response.body).not_to match /confirm_channel_link/
  end

  it "shows the default email channel even when its position is greater than one" do
    course_with_student
    view_context
    sms = @user.communication_channels.create!(:path_type => 'sms', :path => 'someone@somewhere.com')
    email = @user.communication_channels.create!(:path_type => 'email', :path => 'someone@somewhere.com')
    expect(@user.communication_channels.first.state).to eq :unconfirmed
    assign(:email_channels, @user.communication_channels.email.to_a)
    assign(:default_email_channel, @user.communication_channels.email.to_a.first)
    assign(:other_channels, @user.communication_channels.sms.to_a)
    assign(:sms_channels, [])
    assign(:user, @user)

    render :partial => "profile/ways_to_contact"
    expect(response.body).to match /channel default.*channel_#{email.id}/
  end

  it "should show an admin masquerading as a user the confirm link" do
    course_with_student
    account_admin_user
    view_context(@course, @student, @admin)
    @student.communication_channels.create!(:path_type => 'email', :path => 'someone@somewhere.com')
    expect(@student.communication_channels.first.state).to eq :unconfirmed
    assign(:email_channels, @student.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @student)

    render :partial => "profile/ways_to_contact"
    expect(response.body).to match /confirm_channel_link/
  end

  it 'should not show the "I want to log in" for non-default accounts' do
    course_with_student
    view_context
    assign(:email_channels, [])
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)
    assign(:domain_root_account, Account.create!)

    render :partial => "profile/ways_to_contact"
    expect(response.body).not_to match /I want to log in to Canvas using this email address/
  end
end

