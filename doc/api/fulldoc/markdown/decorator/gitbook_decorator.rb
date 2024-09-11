# frozen_string_literal: true

#
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
#

module GitbookDecorator
  # Gitbook specific implementation of the hint method
  # see: https://docs.gitbook.com/content-editor/blocks/hint
  #
  # @param hint_style [String] the style of the hint
  # @param text [String] the hint text
  # @return [String] the hint in Gitbook format
  def hint(hint_style, text)
    "{% hint style=\"#{hint_style}\" %} #{text} {% endhint %}"
  end
end
