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

describe "student dashboard people widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup # Creates 2 courses and a student enrolled in both
    dashboard_people_setup # Add one more teacher and TA to course 1
    set_widget_dashboard_flag(feature_status: true)
  end

  before do
    user_session(@student)
  end

  context "people widget smoke tests" do
    it "displays teachers and TA" do
      go_to_dashboard

      expect(message_instructor_button(@teacher1.id, @course1.id)).to be_displayed
      expect(message_instructor_button(@teacher2.id, @course2.id)).to be_displayed
      expect(message_instructor_button(@ta1.id, @course1.id)).to be_displayed
    end

    it "displays people in pagination" do
      go_to_dashboard

      expect(all_message_buttons.size).to eq(5)
      widget_pagination_button("people", "2").click
      expect(all_message_buttons.size).to eq(1)
    end

    it "can message instructors" do
      go_to_dashboard

      expect(message_instructor_button(@teacher1.id, @course1.id)).to be_displayed
      message_instructor_button(@teacher1.id, @course1.id).click
      wait_for_ajaximations
      expect(send_message_to_modal(@teacher1.name)).to be_displayed
      expect(message_modal_subject_input).to be_displayed
      message_modal_subject_input.send_keys("hello teacher")
      expect(message_modal_body_textarea).to be_displayed
      message_modal_body_textarea.send_keys("just wanted to say hi")
      message_modal_send_button.click
      expect(message_modal_alert).to be_displayed
      expect(message_modal_alert.text).to include("Your message was sent!")
    end
  end
end
