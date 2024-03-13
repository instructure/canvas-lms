# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative "../../common"

module AdminDeveloperKeysPage
  include SeleniumDependencies

  # ---------------------- Selectors ----------------------
  def key_settings_dialog_selector
    "#edit_dialog"
  end

  # ---------------------- Elements ----------------------
  def keys_table
    f("#keys")
  end

  def add_key_button
    f("button.add_key")
  end

  def key_settings_dialog
    f("#edit_dialog")
  end

  def key_name_input
    f("#key_name")
  end

  def key_email_input
    f("#email")
  end

  def key_legacy_redirect_url_input
    f("#redirect_uri")
  end

  def key_redirect_uris_input
    f("#redirect_uris")
  end

  def key_vendor_code_input
    f("#vendor_code")
  end

  def key_icon_url_input
    f("#icon_url")
  end

  def key_notes_input
    f("#notes")
  end

  def save_key_button
    f("button.submit")
  end

  def all_keys
    ff("#keys tbody tr")
  end

  def key_row(key_id)
    fj("tr.key:contains('ID: #{key_id}')")
  end

  def close_dialog_button
    f(".ui-dialog .ui-dialog-titlebar-close")
  end

  def loading_div
    f("#loading")
  end

  def show_all_keys_button
    f("button.show_all")
  end

  def edit_key_button(key_id)
    f("a.edit_link", key_row(key_id))
  end

  def deactivate_key_button(key_id)
    f("a.deactivate_link", key_row(key_id))
  end

  def activate_key_button(key_id)
    f("a.activate_link", key_row(key_id))
  end

  def delete_key_button(key_id)
    f("a.delete_link", key_row(key_id))
  end

  # ------------------ Actions & Methods -------------------
  def visit_developer_page(account_id)
    get("/accounts/#{account_id}/developer_keys")
  end

  def edit_key_name(name)
    replace_content(key_name_input, name)
  end

  def edit_key_email(email)
    replace_content(key_email_input, email)
  end

  def edit_key_redirect_uris(uris)
    replace_content(key_redirect_uris_input, uris)
  end

  def edit_key_legacy_redirect_uri(uri)
    replace_content(key_legacy_redirect_url_input, uri)
  end

  def edit_key_icon_url(icon_url)
    replace_content(key_icon_url_input, icon_url)
  end
end
