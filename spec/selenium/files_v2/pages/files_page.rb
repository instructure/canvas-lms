# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

module FilesPage
  def content
    f("#content")
  end

  def heading
    f("#content h1")
  end

  def all_my_files_button
    fxpath("//button[descendant::text()[contains(., 'All My Files')]]")
  end

  def folder_link(folder_name)
    f("[data-testid='#{folder_name}']")
  end

  def files_usage_text_selector
    "[data-testid='files-usage-text']"
  end

  def files_usage_text
    f(files_usage_text_selector)
  end
end
