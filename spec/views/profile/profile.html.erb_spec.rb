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

describe "/profile/profile" do
  it "should render" do
    course_with_student(:active_user => true)
    view_context

    assigns[:user] = @user
    assigns[:email_channels] = []
    assigns[:other_channels] = []
    assigns[:sms_channels] = []
    assigns[:notification_categories] = Notification.dashboard_categories
    assigns[:policies] = NotificationPolicy.for(@user)
    assigns[:default_pseudonym] = @user.pseudonyms.create!(:unique_id => "unique@example.com", :password => "asdfaa", :password_confirmation => "asdfaa")
    assigns[:pseudonyms] = @user.pseudonyms
    assigns[:password_pseudonyms] = []
    render "profile/profile"
    expect(response).not_to be_nil
  end

  it "should not show the delete link for SIS pseudonyms without manage_sis" do
    account_admin_user_with_role_changes(active_user: true, role_changes: {manage_sis: false})
    view_context

    assigns[:user] = @user
    assigns[:email_channels] = []
    assigns[:other_channels] = []
    assigns[:sms_channels] = []
    assigns[:notification_categories] = Notification.dashboard_categories
    assigns[:policies] = NotificationPolicy.for(@user)
    default_pseudonym = assigns[:default_pseudonym] = @user.pseudonyms.create!(:unique_id => "unique@example.com", :password => "asdfaa", :password_confirmation => "asdfaa")
    sis_pseudonym = @user.pseudonyms.create!(:unique_id => 'sis_unique@example.com') { |p| p.sis_user_id = 'sis_id' }
    assigns[:pseudonyms] = @user.pseudonyms
    assigns[:password_pseudonyms] = []
    render "profile/profile"
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css("#pseudonym_#{default_pseudonym.id} .delete_pseudonym_link").first['style']).to eq ''
    expect(page.css("#pseudonym_#{sis_pseudonym.id} .delete_pseudonym_link").first['style']).to eq 'display: none;'
  end

  it "should not show the pseudonym delete link to non-admins" do
    course_with_student(:active_user => true)
    view_context

    assigns[:user] = @user
    assigns[:email_channels] = []
    assigns[:other_channels] = []
    assigns[:sms_channels] = []
    assigns[:notification_categories] = Notification.dashboard_categories
    assigns[:policies] = NotificationPolicy.for(@user)
    default_pseudonym = assigns[:default_pseudonym] = @user.pseudonyms.create!(:unique_id => "unique@example.com", :password => "asdfaa", :password_confirmation => "asdfaa")
    assigns[:pseudonyms] = @user.pseudonyms
    assigns[:password_pseudonyms] = []
    render "profile/profile"
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css("#pseudonym_#{default_pseudonym.id} .delete_pseudonym_link").first['style']).to eq 'display: none;'
  end
end

