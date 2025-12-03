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

# This service class should be used exclusively to load configuration settings related to
# Canvas Career.
module CanvasCareer
  class Config
    def initialize(root_account, session = nil)
      @root_account = root_account
      @session = session
    end

    def learner_app_launch_url
      override_service.get_override("canvas_career_learner") || config["learner_launch_url"]
    end

    def learning_provider_app_launch_url
      override_service.get_override("canvas_career_learning_provider") || config["learning_provider_launch_url"]
    end

    def theme_url
      config["theme_url"]
    end

    def dark_theme_url
      config["dark_theme_url"]
    end

    # These values are passed to the frontend; they should not contain any secrets!
    def public_app_config(request)
      config["public_app_config"].tap do |c|
        c["hosts"]["canvas"] = request.base_url
        c["experience_preferences"] = experience_preferences
      end
    end

    private

    def config
      @_config ||= YAML.safe_load(DynamicSettings.find(tree: :private)["canvas_career.yml", failsafe: nil] || "{}")
    end

    def override_service
      @_override_service ||= MicrofrontendsReleaseTagOverrideService.new(@session)
    end

    def experience_preferences
      horizon_academic_mode = @root_account.settings[:horizon_academic_mode] || false

      {
        features: {
          notebook: true,
          skillspace: !horizon_academic_mode,
          learner_assist: !horizon_academic_mode,
        }
      }
    end
  end
end
