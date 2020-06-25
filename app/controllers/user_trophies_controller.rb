#
# Copyright (C) 2020 - present Instructure, Inc.
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

class UserTrophiesController < ApplicationController
  before_action :require_user

  def show
    add_crumb(@current_user.short_name, profile_path)
    add_crumb(t("Trophy Case"))
    @show_left_side = true
    @context = @current_user.profile
    set_active_tab('trophy_case')
    css_bundle :trophy_case
    js_bundle :trophy_case
    render html: '', layout: true
  end
end
