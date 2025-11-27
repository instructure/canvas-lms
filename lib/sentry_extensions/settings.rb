# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

module SentryExtensions
  module Settings
    class << self
      def settings
        @sentry_settings ||= build_settings
        @sentry_settings.presence || {}
      end

      def get(name, default = nil, skip_cache: false)
        settings[name.to_sym] || Setting.get(name, default, skip_cache:)
      rescue PG::ConnectionBad
        default
      end

      def reset_settings
        @sentry_settings = nil
      end

      private

      def build_settings
        raw_settings = Canvas.load_config_from_consul("sentry")
        return {} if raw_settings.blank?

        region = Canvas.region_code

        processed_settings = {}
        if region.present?
          processed_settings[:dsn] = raw_settings[:dsn]&.gsub("{region}", region) if raw_settings[:dsn].present?
          processed_settings[:frontend_dsn] = raw_settings[:frontend_dsn]&.gsub("{region}", region) if raw_settings[:frontend_dsn].present?
        else
          processed_settings[:dsn] = raw_settings[:dsn] if raw_settings[:dsn].present?
          processed_settings[:frontend_dsn] = raw_settings[:frontend_dsn] if raw_settings[:frontend_dsn].present?
        end

        processed_settings[:tags] = build_tags

        raw_settings.except(:dsn, :frontend_dsn, :tags).merge(processed_settings).compact
      end

      def build_tags
        {
          "aws_region" => Canvas.region,
          "availability_zone" => Canvas.availability_zone
        }.compact
      end
    end
  end
end
