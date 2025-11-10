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

class Mutations::UpdateWidgetDashboardConfig < Mutations::BaseMutation
  argument :config, String, required: true

  field :config, String, null: true

  def resolve(input:)
    config_value = input[:config].present? ? JSON.parse(input[:config]) : nil
    config_value = nil if config_value.is_a?(String) && config_value.empty?
    current_user.set_preference(:widget_dashboard_config, config_value)
    { config: config_value&.to_json }
  rescue JSON::ParserError
    validation_error(I18n.t("Invalid JSON format for widget dashboard configuration"))
  end
end
