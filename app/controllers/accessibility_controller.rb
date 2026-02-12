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

class AccessibilityController < ApplicationController
  before_action :require_context
  before_action :require_user
  before_action :check_authorized_action

  def index
    @page_title = t("titles.accessibility_checker", "Accessibility Checker")
    add_crumb(t("titles.accessibility_checker", "Accessibility Checker"))
    set_active_tab "accessibility"
    @show_left_side = true
    @collapse_course_menu = false
    js_bundle :accessibility_checker
    js_env(SCAN_DISABLED: @context.exceeds_accessibility_scan_limit?)
    render html: "".html_safe, layout: true
  end

  private

  def check_authorized_action
    return render_unauthorized_action unless tab_enabled?(Course::TAB_ACCESSIBILITY)

    authorized_action(@context, @current_user, [:read, :update])
  end
end
