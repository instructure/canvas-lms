#
# Copyright (C) 2012 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/common')

describe "profile communication settings new ui" do
  include_context "in-process server selenium tests"

  before :each do
    Account.site_admin.enable_feature!(:notification_update_account_ui)

    Notification.create(:name => "Conversation Message", :category => "DiscussionEntry")
    Notification.create(:name => "Added To Conversation", :category => "Discussion")
    Notification.create(:name => "GradingStuff1", :category => "Grading")
    @sub_comment = Notification.create(:name => "Submission Comment1", :category => "Submission Comment")

    course_with_teacher_logged_in
  end

  it "should render" do
    get "/profile/communication"
    expect(f('#breadcrumbs')).to include_text('Account Notification Settings')
    expect(f("h1").text).to eq "Account Notification Settings"
    expect(fj("div:contains('Account-level notifications apply to all courses.')")).to be
  end

  it "should display the users email address as channel" do
    get "/profile/communication"
    expect(fj("th[scope='col'] span:contains('email')")).to be
    expect(fj("th[scope='col'] span:contains('nobody@example.com')")).to be
  end

  it "should display an SMS number as channel" do
    communication_channel(@user, {username: '8011235555@vtext.com', path_type: 'sms', active_cc: true})
    get "/profile/communication"
    expect(fj("span:contains('sms')")).to be
    expect(fxpath("//span[contains(text(),'8011235555@vtext')]")).to be
  end
end
