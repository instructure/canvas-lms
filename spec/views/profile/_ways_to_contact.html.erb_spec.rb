# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "profile/_ways_to_contact" do
  it "renders" do
    course_with_student
    view_context
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, [])
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render partial: "profile/ways_to_contact"
    expect(response).not_to be_nil
  end

  describe "can_edit_channels" do
    before do
      account_admin_user
      view_context
      communication_channel(@user, { username: "someone@somewhere.com", active_cc: true })
      assign(:email_channels, @user.communication_channels.to_a)
      assign(:other_channels, [])
      assign(:sms_channels, [])
      assign(:user, @user)
    end

    it "allows creation when can_edit_channels is true" do
      assign(:user_data, { can_edit_channels: true })

      render partial: "profile/ways_to_contact"
      expect(response.body).to match(/delete_channel_link/)
    end

    it "allows deletion when can_edit_channels is true" do
      assign(:user_data, { can_edit_channels: true })

      render partial: "profile/ways_to_contact"
      expect(response.body).to match(/add_contact_link/)
    end

    it "does not allow creation when can_edit_channels is false" do
      assign(:user_data, { can_edit_channels: false })

      render partial: "profile/ways_to_contact"
      expect(response.body).not_to match(/delete_channel_link/)
    end

    it "does not allow deletion when can_edit_channels is false" do
      assign(:user_data, { can_edit_channels: false })

      render partial: "profile/ways_to_contact"
      expect(response.body).not_to match(/add_contact_link/)
    end
  end

  it "does not show a student the confirm link" do
    course_with_student
    view_context
    communication_channel(@user, { username: "someone@somewhere.com" })
    expect(@user.communication_channels.first.state).to eq :unconfirmed
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, @user.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render partial: "profile/ways_to_contact"
    expect(response.body).not_to match(/confirm_channel_link/)
  end

  it "shows an admin the confirm link" do
    account_admin_user
    view_context
    communication_channel(@user, { username: "someone@somewhere.com" })
    expect(@user.communication_channels.first.state).to eq :unconfirmed
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, @user.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render partial: "profile/ways_to_contact"
    expect(response.body).to match(/confirm_channel_link/)
  end

  it "does not show confirm link for confirmed channels" do
    account_admin_user
    view_context
    communication_channel(@user, { username: "someone@somewhere.com", active_cc: true })
    expect(@user.communication_channels.first.state).to eq :active
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, @user.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)

    render partial: "profile/ways_to_contact"
    expect(response.body).not_to match(/confirm_channel_link/)
  end

  it "does not show confirm link for push channels" do
    account_admin_user
    view_context
    communication_channel(@user, { username: "someone@somewhere.com", path_type: "push", active_cc: true })
    expect(@user.communication_channels.first.state).to eq :active
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, [])
    assign(:other_channels, @user.communication_channels.to_a)
    assign(:sms_channels, [])
    assign(:user, @user)

    render partial: "profile/ways_to_contact"
    expect(response.body).to match(%r{<div.*>For All Devices</div>})
    expect(response.body).to_not match(%r{<a.*>For All Devices</a>})
  end

  it "shows the default email channel even when its position is greater than one" do
    course_with_student
    view_context
    communication_channel(@user, { username: "someone@somewhere.com", path_type: "sms" })
    email = communication_channel(@user, { username: "someone@somewhere.com" })
    expect(@user.communication_channels.first.state).to eq :unconfirmed
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, @user.communication_channels.email.to_a)
    assign(:default_email_channel, @user.communication_channels.email.to_a.first)
    assign(:other_channels, @user.communication_channels.sms.to_a)
    assign(:sms_channels, [])
    assign(:user, @user)

    render partial: "profile/ways_to_contact"
    expect(response.body).to match(/channel default.*channel_#{email.id}/)
  end

  it "shows an admin masquerading as a user the confirm link" do
    course_with_student
    account_admin_user
    view_context(@course, @student, @admin)
    communication_channel(@student, { username: "someone@somewhere.com" })
    expect(@student.communication_channels.first.state).to eq :unconfirmed
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, @student.communication_channels.to_a)
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @student)

    render partial: "profile/ways_to_contact"
    expect(response.body).to match(/confirm_channel_link/)
  end

  it 'does not show the "I want to log in" for non-default accounts' do
    course_with_student
    view_context
    assign(:user_data, { can_edit_channels: true })
    assign(:email_channels, [])
    assign(:other_channels, [])
    assign(:sms_channels, [])
    assign(:user, @user)
    assign(:domain_root_account, Account.create!)

    render partial: "profile/ways_to_contact"
    expect(response.body).not_to match(/I want to log in to Canvas using this email address/)
  end
end
