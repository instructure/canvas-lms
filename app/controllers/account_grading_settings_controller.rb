# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

# TODO: eliminate this controller in favor of the generic ReactContentController
# once the legacy grading_periods sub tab is reworked to not need the .scss
# bundles included below with css_bundle
class AccountGradingSettingsController < ApplicationController
  before_action :require_context
  add_crumb(proc { t "#crumbs.grading_settings", "Grading" }) { |c| c.send :named_context_url, c.instance_variable_get(:@context), :context_grading_settings_url }
  before_action { |c| c.active_tab = "grading_standards" }
  before_action :require_user

  def index
    js_bundle :react_content_router
    css_bundle :grading_period_sets, :enrollment_terms
    render html: "".html_safe, layout: true
  end
end
