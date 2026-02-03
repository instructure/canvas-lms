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
require_relative "../dashboard/pages/dashboard_page"

describe "widget dashboard toggle", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon
  include DashboardPage

  #------------------------------ Selectors ------------------------------
  def switch_to_new_dashboard_button_selector
    "[data-testid='switch-to-new-dashboard-button']"
  end

  def switch_to_old_dashboard_button_selector
    "[data-testid='switch-to-old-dashboard-button']"
  end

  def widget_container_prefix_selector
    "[data-testid^='widget-container-']"
  end

  #------------------------------ Elements ------------------------------
  def switch_to_new_dashboard_button
    f(switch_to_new_dashboard_button_selector)
  end

  def switch_to_old_dashboard_button
    f(switch_to_old_dashboard_button_selector)
  end

  def legacy_dashboard_card_container
    f(card_container_selector)
  end

  def widget_containers
    ff(widget_container_prefix_selector)
  end

  #------------------------------ Helpers ------------------------------
  def legacy_dashboard_displayed?
    element_exists?(card_container_selector) && !element_exists?(widget_container_prefix_selector)
  end

  def widget_dashboard_displayed?
    element_exists?(widget_container_prefix_selector) && !element_exists?(card_container_selector)
  end

  before :once do
    dashboard_student_setup
    Account.default.enable_feature!(:widget_dashboard)
  end

  before do
    user_session(@student)
  end

  context "when widget_dashboard feature flag is enabled" do
    it "allows student to toggle from legacy dashboard to widget dashboard and back" do
      go_to_dashboard

      expect(legacy_dashboard_card_container).to be_displayed
      expect(switch_to_new_dashboard_button).to be_displayed
      expect(element_exists?(switch_to_old_dashboard_button_selector)).to be_falsey

      switch_to_new_dashboard_button.click
      wait_for_ajaximations

      expect(widget_containers.size).to be > 0
      expect(switch_to_old_dashboard_button).to be_displayed
      expect(element_exists?(card_container_selector)).to be_falsey

      switch_to_old_dashboard_button.click
      wait_for_ajaximations

      expect(legacy_dashboard_card_container).to be_displayed
      expect(switch_to_new_dashboard_button).to be_displayed
      expect(element_exists?(switch_to_old_dashboard_button_selector)).to be_falsey
    end

    it "persists widget dashboard preference after page reload" do
      go_to_dashboard

      expect(legacy_dashboard_card_container).to be_displayed
      switch_to_new_dashboard_button.click
      wait_for_ajaximations

      expect(widget_containers.size).to be > 0

      refresh_page
      wait_for_ajaximations

      expect(widget_containers.size).to be > 0
      expect(switch_to_old_dashboard_button).to be_displayed
    end

    it "persists legacy dashboard preference after switching back" do
      go_to_dashboard
      switch_to_new_dashboard_button.click
      wait_for_ajaximations

      expect(widget_containers.size).to be > 0

      switch_to_old_dashboard_button.click
      wait_for_ajaximations

      expect(legacy_dashboard_card_container).to be_displayed

      refresh_page
      wait_for_ajaximations

      expect(legacy_dashboard_card_container).to be_displayed
      expect(switch_to_new_dashboard_button).to be_displayed
    end
  end
end
