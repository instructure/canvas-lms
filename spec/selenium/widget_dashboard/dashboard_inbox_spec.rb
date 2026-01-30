# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "page_objects/widget_dashboard_page"
require_relative "../helpers/student_dashboard_common"

describe "student dashboard inbox widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup
    dashboard_conversation_setup
    set_widget_dashboard_flag(feature_status: true)
  end

  context "inbox widget smoke tests" do
    before do
      user_session(@student)
    end

    it "can filter messages by read status" do
      go_to_dashboard

      expect(inbox_filter_select).to be_displayed
      expect(all_inbox_message_items.size).to eq(3)
      filter_inbox_messages_by("All")
      expect(all_inbox_message_items.size).to eq(5)
    end

    it "persists filter preference across sessions" do
      go_to_dashboard
      filter_inbox_messages_by("All")

      refresh_page
      wait_for_ajaximations
      expect(inbox_filter_select).to have_value("All")

      destroy_session
      user_session(@student)
      go_to_dashboard
      expect(inbox_filter_select).to have_value("All")
    end

    it "displays maximum 5 messages" do
      create_multiple_conversations(@student, @teacher1, 3, "unread")
      go_to_dashboard
      expect(all_inbox_message_items.size).to eq(5)
      expect(inbox_show_all_messages_link).to be_displayed
    end

    it "navigates to conversations page when clicking show all messages link" do
      go_to_dashboard

      click_inbox_show_all_messages_link
      expect(driver.current_url).to include("/conversations")
    end
  end
end
