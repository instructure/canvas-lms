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
require_relative '../../common'

module AccountContentSharePage
  # ---------------------- Elements ----------------------

  def content_share_main_content
    f('#content')
  end

  def page_application_container
    f('#application')
  end

  def received_table_rows
    ff('table tr')
  end

  def received_item_row(item_name)
    fj("tr:contains('#{item_name}')")
  end

  def manage_received_item_button(item_name)
    fj("button:contains('Manage options for #{item_name}')")
  end

  def received_item_actions_menu
    ff("ul[role='menu'] li")
  end

  def remove_received_item
    fj("li:contains('Remove')")
  end

  def unread_item_button_icon(item_name)
    fj("button:contains('#{item_name} is unread, click to mark as read')")
  end

  def read_item_button_icon(item_name)
    fj("button:contains('#{item_name} has been read')")
  end

  def import_content_share
    f("span[data-testid='import-menu-action']")
  end

  # ---------------------- Actions -----------------------

  def visit_content_share_page
    get "/profile/content_shares"
  end

  # ---------------------- Methods -----------------------
  
end