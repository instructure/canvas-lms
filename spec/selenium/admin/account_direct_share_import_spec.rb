# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../common'
require_relative 'pages/admin_account_page'
require_relative 'pages/account_content_share_page'

describe "direct share page" do
  include_context "in-process server selenium tests"
  include AdminSettingsPage
  include AccountContentSharePage

  # Two courses and two teachers
  # Teacher1 sends an item to Teacher2
  before :once do
    course_with_teacher(name: 'First Course', active_all: true)
    @course_1 = @course
    @teacher_1 = @teacher
    course_with_teacher(name: 'Second Course', active_all: true)
    @course_2 = @course
    @teacher_2 = @teacher
    @course_1.require_assignment_group
    @assignment_1 = @course_1.assignments.create!(:title => 'Assignment First', :points_possible => 10)
    assignment_model(course: @course_1, name: 'assignment to share')

    @export_1 = @course_1.content_exports.create!(workflow_state: 'exported', settings: {"selected_content" => {"assignments" => {CC::CCHelper.create_key(@assignment_1) => '1'}}})
    @export_2 = @course_1.content_exports.create!(workflow_state: 'exported', settings: {"selected_content" => {"assignments" => {CC::CCHelper.create_key(@assignment_1) => '1'}}})
    @export_3 = @course_1.content_exports.create!(workflow_state: 'exported', settings: {"selected_content" => {"assignments" => {CC::CCHelper.create_key(@assignment_1) => '1'}}})
    @sent_share = @teacher_1.sent_content_shares.create! name: 'a-unread share1', content_export: @export_1, read_state: 'unread'
    @unread_share1 = @teacher_2.received_content_shares.create! name: 'a-unread share1', content_export: @export_1, sender: @teacher_1, read_state: 'unread'
    @unread_share2 = @teacher_2.received_content_shares.create! name: 'b-unread share2', content_export: @export_2, sender: @teacher_1, read_state: 'unread'
    @read_share = @teacher_2.received_content_shares.create! name: 'c-read share', content_export: @export_3, sender: @teacher_1, read_state: 'read'
  end

  before :each do
    user_session @teacher_2
    visit_content_share_page
  end

  it "notifies on user global nav profile avatar" do
    expect(global_nav_profile_link.text).to include '2 unread shares.'
  end

  it "notifies on global nav tray" do
    global_nav_profile_link.click
    wait_for_ajaximations
    expect(profile_tray_menu_items.text).to match /Shared Content/i
    expect(profile_tray_menu_items.text).to include '2 unread.'
  end

  it "displays new share on received tab in most-recent-first order" do
    expect(content_share_main_content.text).to include 'Received Content'
    expect(received_table_rows[1].text).to include 'c-read share'
    expect(received_table_rows[2].text).to include 'b-unread share2'
    expect(received_table_rows[3].text).to include 'a-unread share1'
  end

  it "marks an unread received item as read when clicked" do
    expect(received_table_rows[3].text).to include 'a-unread share1 mark as read'

    unread_item_button_icon(@unread_share1.name).click
    wait_for_ajaximations
    expect(received_table_rows[3].text).to include 'a-unread share1 mark as unread'
  end

  it "marks a read received item as unread when clicked" do
    expect(received_table_rows[1].text).to include 'c-read share mark as unread'

    read_item_button_icon(@read_share.name).click
    wait_for_ajaximations
    expect(received_table_rows[1].text).to include 'c-read share mark as read'
  end

  it "displays manage item menu options" do
    manage_received_item_button(@read_share.name).click

    expect(received_item_actions_menu[0].text).to match(/Preview/i)
    expect(received_item_actions_menu[1].text).to match(/Import/i)
    expect(received_item_actions_menu[2].text).to match(/Remove/i)
  end

  it "allows removal of a received item" do
    manage_received_item_button(@read_share.name).click
    remove_received_item.click
    driver.switch_to.alert.accept
    wait_for_ajaximations
    expect(content_share_main_content.text).not_to include 'c-read share'
  end

  # it "launches the Import tray for a content share" do
  #   skip('will be fixed in a new PS ADMIN-3012')
  #   manage_received_item_button(@read_share.name).click
  #   import_content_share.click

  #   expect(page_application_container).to contain_css("[role='dialog'][aria-label='Import...']")
  #end
end
