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

module Api::V1::Plugin
  include Api::V1::Json

  ENCRYPTED_SUFFIXES = %w[dec salt enc].freeze

  # unfortunately we can't get some information like created and updated at out of plugin.settings that we can off of
  # plugin_setting, so we'll pass both into this method.
  def plugin_json(plugin, plugin_setting, user, session, _opts = {})
    api_json(plugin_setting, user, session, only: %w[settings created_at updated_at]).tap do |hash|
      hash["id"] = plugin.id

      hash["plugin_setting"] = { disabled: plugin_setting.disabled }
      hash["settings"]&.delete_if { |k, _| k.start_with?(*plugin.encrypted_settings) }
    end
  end
end
