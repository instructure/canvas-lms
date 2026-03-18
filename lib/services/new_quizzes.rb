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

module Services
  class NewQuizzes
    NEW_QUIZZES_CLOUDFRONT_HOST_PRODUCTION_KEY = "new_quizzes_cloudfront_host_production"
    NEW_QUIZZES_CLOUDFRONT_HOST_BETA_KEY = "new_quizzes_cloudfront_host_beta"
    NEW_QUIZZES_CLOUDFRONT_HOST_EDGE_KEY = "new_quizzes_cloudfront_host_edge"
    NEW_QUIZZES_IMPORTING_TIMEOUT_IN_MINUTES_KEY = "new_quizzes_importing_timeout_in_minutes"

    def self.importing_timeout_in_minutes
      value = config[NEW_QUIZZES_IMPORTING_TIMEOUT_IN_MINUTES_KEY]
      Integer(value).minutes
    rescue => e
      message = "Services::NewQuizzes#importing_timeout_in_minutes can't convert value (#{value}): #{e.message}"
      Rails.logger.error(message)
      Rails.logger.error(e.backtrace.join("\n"))
      Sentry.capture_exception(e) do |scope|
        scope.set_extra(message:)
      end

      30.minutes
    end

    def self.launch_url(tool_url: nil)
      return "#{config[NEW_QUIZZES_CLOUDFRONT_HOST_EDGE_KEY]}/none/remoteEntry.js" if Rails.env.development?

      "#{cloudfront_host}/#{region(tool_url:)}/remoteEntry.js"
    end

    def self.ui_version(tool_url: nil)
      return "none" if Rails.env.development?

      region(tool_url:)
    end

    def self.cloudfront_host
      case environment
      when "production"
        config[NEW_QUIZZES_CLOUDFRONT_HOST_PRODUCTION_KEY]
      when "beta"
        config[NEW_QUIZZES_CLOUDFRONT_HOST_BETA_KEY] || config[NEW_QUIZZES_CLOUDFRONT_HOST_PRODUCTION_KEY]
      when "edge"
        config[NEW_QUIZZES_CLOUDFRONT_HOST_EDGE_KEY] || config[NEW_QUIZZES_CLOUDFRONT_HOST_PRODUCTION_KEY]
      else
        raise ArgumentError, "Unknown environment: #{environment}"
      end
    end

    def self.region(tool_url: nil)
      return "edge" if tool_url.present? && tool_url.include?("quiz-lti-pdx-edge")

      ApplicationController.region || begin
        Rails.logger.warn("ApplicationController.region is not set, defaulting to 'us-east-1'")
        "us-east-1"
      end
    end

    def self.environment
      env = ENV.fetch("CANVAS_ENVIRONMENT") do
        Rails.logger.warn("CANVAS_ENVIRONMENT is not set, defaulting to 'edge'")
        "edge"
      end
      env = "edge" if env == "cd"
      env
    end

    class << self
      private

      Canvas::Reloader.on_reload do
        @config = nil
      end

      def config
        @config ||= YAML.safe_load(DynamicSettings.find(tree: :private)["new_quizzes.yml", failsafe: nil] || "{}")
      end
    end
  end
end
