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
  before_action :validate_allowed

  def index
    js_bundle :accessibility_checker

    render html: '<div id="accessibility-checker-container"></div>'.html_safe, layout: true
  end

  private

  def validate_allowed
    return render_unauthorized_action unless tab_enabled?(Course::TAB_ACCESSIBILITY)

    authorized_action(@context, @current_user, [:read, :update])
  end
end
