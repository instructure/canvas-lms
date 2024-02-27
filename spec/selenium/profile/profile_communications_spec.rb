# frozen_string_literal: true

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
require_relative "../common"

describe "profile communication settings" do
  include_context "in-process server selenium tests"

  before :once do
    Notification.create(name: "DiscussionEntry", category: "DiscussionEntry")
    Notification.create(name: "Conversation Message", category: "Conversation Message")
    Notification.create(name: "Conversation Created", category: "Conversation Created")
    Notification.create(name: "GradingStuff1", category: "Grading")
    @sub_comment = Notification.create(name: "Submission Comment1", category: "Submission Comment")
  end

  let(:sns_response) { double(data: { endpointarn: "endpointarn" }) }
  let(:sns_client) { double(create_platform_endpoint: sns_response) }
  let(:sns_developer_key_sns_field) { sns_client }

  let(:sns_developer_key) do
    allow(DeveloperKey).to receive(:sns).and_return(sns_developer_key_sns_field)
    dk = DeveloperKey.default
    dk.sns_arn = "apparn"
    dk.save!
    dk
  end

  let(:sns_access_token) { @user.access_tokens.create!(developer_key: sns_developer_key) }
  let(:sns_channel) { communication_channel(@user, { username: "push", path_type: CommunicationChannel::TYPE_PUSH }) }

  context "as teacher" do
    before do
      course_with_teacher_logged_in
    end

    it "shows unsupported push categories as disabled" do
      Notification.create(category: "Announcement Created By You", name: "Announcement Created By You")
      Notification.create(category: "All Submissions", name: "All Submissions")

      communication_channel(@user, { username: "8011235555@vtext.com", path_type: "push", active_cc: true })
      get "/profile/communication"

      expect(
        fj("tr[data-testid='announcement_created_by_you'] button:contains('Notifications unsupported')")
      ).to be_present

      expect(
        fj("tr[data-testid='all_submissions'] button:contains('Notifications unsupported')")
      ).to be_present
    end

    it "renders" do
      get "/profile/communication"
      expect(f("#breadcrumbs")).to include_text("Notification Settings")
      expect(f("h1").text).to eq "Notification Settings"
      expect(fj("div:contains('Account-level notifications apply to all courses.')")).to be_present
      expect(fj("thead span:contains('Course Activities')")).to be_present
      expect(fj("thead span:contains('Discussions')")).to be_present
      expect(fj("thead span:contains('Conversations')")).to be_present
    end

    it "displays the users email address as channel" do
      get "/profile/communication"
      expect(fj("th[scope='col'] span:contains('email')")).to be
      expect(fj("th[scope='col'] span:contains('nobody@example.com')")).to be
    end

    it "does not display a SMS number as channel" do
      communication_channel(@user, { username: "8011235555@vtext.com", path_type: "sms", active_cc: true })

      get "/profile/communication"
      expect(f("thead")).not_to contain_jqcss("span:contains('sms')")
      expect(f("thead")).not_to contain_jqcss("span:contains('8011235555@vtext.com')")
    end

    it "saves a user-pref checkbox change" do
      Account.default.settings[:allow_sending_scores_in_emails] = true
      Account.default.save!
      # set the user's initial user preference and verify checked or unchecked
      @user.preferences[:send_scores_in_emails] = false
      @user.save!

      get "/profile/communication"
      f("tr[data-testid='grading'] label").click
      wait_for_ajaximations
      # test data stored
      @user.reload
      expect(@user.preferences[:send_scores_in_emails]).to be true
    end

    it "only displays immediately and off for sns channels" do
      sns_channel
      get "/profile/communication"
      focus_button = ff("tr[data-testid='grading'] button")[1]
      focus_button.click
      wait_for_ajaximations
      menu = ff("ul[aria-labelledby='#{focus_button.attribute("data-position-target")}'] li")
      expect(menu.size).to eq 2
      expect(menu[0].text).to eq "Notify immediately"
      expect(menu[1].text).to eq "Notifications off"
    end

    it "loads an existing frequency setting and save a change" do
      channel = communication_channel(@user, { username: "8011235555@vtext.com", active_cc: true })
      # Create a notification policy entry as an existing setting.
      policy = channel.notification_policies.where(notification_id: @sub_comment.id).first
      policy.frequency = Notification::FREQ_DAILY
      policy.save!
      desired_setting = "Notify immediately"
      get "/profile/communication"
      focus_button = ff("tr[data-testid='submission_comment'] button")[1]
      focus_button.click
      wait_for_ajaximations
      fj("ul li:contains('#{desired_setting}') span").click
      wait_for_ajaximations
      focus_button_changed = ff("tr[data-testid='submission_comment'] button")[1]
      expect(focus_button_changed.text).to eq desired_setting
      policy.reload
      expect(policy.frequency).to eq Notification::FREQ_IMMEDIATELY
    end

    it "removes Conversations category when opted out" do
      Account.site_admin.enable_feature! :allow_opt_out_of_inbox
      @user.preferences[:disable_inbox] = true
      @user.save!
      get "/profile/communication"
      expect(fj("thead span:contains('Course Activities')")).to be_present
      expect(fj("thead span:contains('Discussions')")).to be_present
      expect(f("thead")).not_to contain_jqcss("span:contains('Conversations')")
    end
  end

  it "renders for a user with no enrollments" do
    user_logged_in(username: "somebody@example.com")
    get "/profile/communication"
    expect(fj("th[scope='col'] span:contains('email')")).to be
    expect(fj("th[scope='col'] span:contains('somebody@example.com')")).to be
  end
end
