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

module SendToDialogPage
  # ------------------------------ Selectors -----------------------------
  
  def send_to_dialog_css_selector
    "[role='dialog'][aria-label='Send To...']"
  end

  # ------------------------------ Elements ------------------------------
  
  def send_to_dialog
    f(send_to_dialog_css_selector)
  end

  def user_search
    f("input[placeholder='Begin typing to search']")
  end

  def user_dropdown(user_name)
    fj("div span:contains(#{user_name})")
  end

  def send_button
    fj("button:contains('Send')")
  end

  def starting_send_operation_alert
    f("[role=alert]")
  end

  # ------------------------------ Actions ------------------------------

end
