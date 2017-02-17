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
require File.expand_path(File.dirname(__FILE__) + '/common')

describe "profile communication settings" do
  include_context "in-process server selenium tests"
  before :each do
    user_logged_in(:username => 'somebody@example.com')

    Notification.create(:name => "Conversation Message", :category => "DiscussionEntry")
    Notification.create(:name => "Added To Conversation", :category => "Discussion")
    Notification.create(:name => "GradingStuff1", :category => "Grading")
    @sub_comment = Notification.create(:name => "Submission Comment1", :category => "Submission Comment")
  end

  # Using javascript, trigger a mouseenter event to hide text and display buttons.
  def mouse_enter_cell(category, channel_id)
    driver.execute_script("$('#notification-preferences .comm-event-option[data-category=#{category}][data-channelid=#{channel_id}]').trigger('mouseenter')")
  end

  # Using javascript, trigger a mouseleave event to hide buttons and display text.
  def mouse_leave_cell(category, channel_id)
    driver.execute_script("$('#notification-preferences .comm-event-option[data-category=#{category}][data-channelid=#{channel_id}]').trigger('mouseleave')")
  end

  # Find the frequency cell for the category and channel.
  def find_frequency_cell(category, channel_id)
    fj("td.comm-event-option[data-category='#{category}'][data-channelid=#{channel_id}]")
  end

  it "should render" do
    get "/profile/communication"
    # Page title should match expected
    expect(driver.execute_script("return document.title")).to eq 'Notification Preferences'
    # Expect breadcrumbs to correctly display page name
    expect(f('#breadcrumbs')).to include_text('Notification Preferences')
    # Expect h1 with
    expect(f('#content > h1').text).to eq 'Notification Preferences'
  end

  it "should display the users email address as channel" do
    get "/profile/communication"
    wait_for_ajaximations
    expect(fj('th.comm-channel:first')).to include_text('Email Address')
    expect(fj('th.comm-channel:first')).to include_text('somebody@example.com')
  end

  it "should display an SMS number as channel" do
    channel = @user.communication_channels.create(:path => "8011235555@vtext.com", :path_type => "sms")
    channel.confirm
    get "/profile/communication"
    wait_for_ajaximations
    expect(fj('tr.grouping:first th.comm-channel:last')).to include_text('Cell Number')
    expect(fj('tr.grouping:first th.comm-channel:last')).to include_text('8011235555@vtext.com')
  end

  let(:sns_response) { stub(data: {endpointarn: 'endpointarn'}) }
  let(:sns_client) { stub(create_platform_endpoint: sns_response) }
  let(:sns_developer_key_sns_field) { sns_client }

  let(:sns_developer_key) do
    DeveloperKey.stubs(:sns).returns(sns_developer_key_sns_field)
    dk = DeveloperKey.default
    dk.sns_arn = 'apparn'
    dk.save!
    dk
  end

  let(:sns_access_token) { @user.access_tokens.create!(developer_key: sns_developer_key) }
  let(:sns_channel) { @user.communication_channels.create(path_type: CommunicationChannel::TYPE_PUSH, path: 'push') }

  it "should display an sns channel" do
    sns_channel
    get "/profile/communication"
    wait_for_ajaximations
    expect(fj('tr.grouping:first th.comm-channel:last')).to include_text('Push Notification')
  end

  it "should only display asap and never for sns channels" do
    sns_channel
    get "/profile/communication"
    wait_for_ajaximations
    cell = find_frequency_cell("grading", sns_channel.id)
    buttons = ff('input', cell)
    expect(buttons[0]).to have_attribute('value', 'immediately')
    expect(buttons[1]).to have_attribute('value', 'never')
  end

  it "should load the initial state of a user-pref checkbox" do
    # set the user's initial user preference and verify checked or unchecked
    @user.preferences[:send_scores_in_emails] = false
    @user.save!
    get "/profile/communication"
    wait_for_ajaximations
    expect(is_checked('.user-pref-check[name=send_scores_in_emails]')).to be_falsey
  end

  it "should save a user-pref checkbox change" do
    # Enable the setting to be changed first...
    Account.default.settings[:allow_sending_scores_in_emails] = true
    Account.default.save!
    # set the user's initial user preference and verify checked or unchecked
    @user.preferences[:send_scores_in_emails] = false
    @user.save!
    get "/profile/communication"
    f('.user-pref-check[name=send_scores_in_emails]').click

    wait_for_ajaximations

    # test data stored
    @user.reload
    expect(@user.preferences[:send_scores_in_emails]).to eq true
  end

  it "should load an existing frequency setting and save a change" do
    channel = @user.communication_channels.create(:path => "8011235555@vtext.com", :path_type => "email")
    channel.confirm
    # Create a notification policy entry as an existing setting.
    policy = NotificationPolicy.new(:communication_channel_id => channel.id, :notification_id => @sub_comment.id)
    policy.frequency = Notification::FREQ_DAILY
    policy.save!
    get "/profile/communication"
    category_string = @sub_comment.category.underscore.gsub(/\s/, '_')
    cell = find_frequency_cell(category_string, channel.id)
    # validate existing text is shown correctly (text display and button state)
    daily_input = cell.find_element(:css, "input#cat_#{category_string}_ch_#{channel.id}_daily")
    expect(daily_input).to be_selected

    # Change to a different value and verify flash and the save. (click on the radio)
    immediate_input = cell.find_element(:css, "input#cat_#{category_string}_ch_#{channel.id}_immediately")
    driver.execute_script("arguments[0].click()", immediate_input)
    expect(immediate_input).to be_selected

    wait_for_ajaximations

    # test data stored
    policy.reload
    expect(policy.frequency).to eq Notification::FREQ_IMMEDIATELY
  end

  context "accessibility usage" do
    it "should be navigable by keyboard only"
  end
end
