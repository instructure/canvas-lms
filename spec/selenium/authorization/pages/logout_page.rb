# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'


module LogoutPage
  #------------------------- Selectors --------------------------
  def logout_confirm_btn_selector
    '#Button--logout-confirm'
  end

  #------------------------- Elements ---------------------------
  def logout_confirm_btn
    f(logout_confirm_btn_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def visit_logout_page
    get "/logout"
  end

  def confirm_logout
    logout_confirm_btn.click
  end
end
