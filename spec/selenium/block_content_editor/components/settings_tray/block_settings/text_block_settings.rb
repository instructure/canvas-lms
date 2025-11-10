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

require_relative "../../../../common"
require_relative "../settings_group_component"
require_relative "shared/block_title_toggle"
require_relative "shared/color_settings"

class TextBlockSettings
  include SeleniumDependencies

  attr_reader :block_title_toggle, :color_settings

  def initialize
    @block_title_toggle = BlockTitleToggle.new
    @color_settings = ColorSettings.new
  end
end
