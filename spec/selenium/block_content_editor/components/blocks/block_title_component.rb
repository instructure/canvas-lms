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

require_relative "block_component"
require_relative "../settings_tray/block_settings/media_block_settings"

class BlockTitleComponent
  include SeleniumDependencies

  def initialize(block)
    @block = block
  end

  def title_selector
    ".base-block-layout h2"
  end

  def title_input
    fj("label:contains('Block title') input", @block)
  end

  def title
    f("h2", @block)
  end

  def is_title_present?
    element_exists?(title_selector)
  end
end
