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

module LLMConfigs
  def self.configs
    @configs ||= Dir[Rails.root.join("config/llm_configs/*.yml").to_s].each_with_object({}) do |path, config_hash|
      name = File.basename(path, ".yml")
      config_data = YAML.load_file(path)

      begin
        config_item = LLMConfig.new(
          name: config_data["name"],
          model_id: config_data["model_id"],
          rate_limit: config_data["rate_limit"],
          template: config_data["template"],
          options: config_data["options"]
        )
      rescue ArgumentError => e
        raise ArgumentError, "Error in LLM config #{name}: #{e.message}"
      end

      config_hash[name] = config_item
    end
  end

  def self.config_for(prompt_type)
    configs[prompt_type.to_s]
  end
end
