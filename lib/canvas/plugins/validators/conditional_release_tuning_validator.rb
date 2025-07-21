# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Canvas::Plugins::Validators::ConditionalReleaseTuningValidator
  def self.validate(settings, plugin_setting)
    result = {}
    if settings.keys.length != 1 || settings.keys[0] != "priority"
      plugin_setting.errors.add(:base, I18n.t("Conditional release tuning settings can only accept priority"))
    elsif !%w[low medium high].include? settings["priority"]
      plugin_setting.errors.add(:base, I18n.t("Conditional release tuning priority must be one of low, medium, high"))
    else
      result = settings
    end

    return unless plugin_setting.errors.empty?

    result.with_indifferent_access
  end
end
