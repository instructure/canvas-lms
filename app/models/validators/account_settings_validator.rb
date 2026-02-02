# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module Validators
  class AccountSettingsValidator < ActiveModel::Validator
    DISCOVERY_PAGE_REQUIRED_KEYS = %i[authentication_provider_id label].freeze
    DISCOVERY_PAGE_OPTIONAL_KEYS = %i[icon_url].freeze

    def validate(record)
      # Discovery Page
      validate_discovery_page(record) if record.settings[:discovery_page].present? && record.discovery_page_changed?
    end

    private

    def validate_discovery_page(record)
      data = record.settings[:discovery_page]

      # Load authentication providers into memory and validate there
      # to avoid N+1 queries during #validate_discovery_page_entry
      record.authentication_providers.load unless record.authentication_providers.loaded?

      %i[primary secondary].each do |section|
        unless data[section].is_a?(Array)
          record.errors.add(:settings, "discovery_page.#{section} must be an array")
          next
        end

        data[section].each_with_index do |entry, index|
          validate_discovery_page_entry(record, section, entry, index)
        end
      end
    end

    def validate_discovery_page_entry(record, section, entry, index)
      provider_id = entry[:authentication_provider_id].to_i
      unless record.authentication_providers.find { it.id == provider_id }&.active?
        record.errors.add(:settings, "discovery_page.#{section}[#{index}].authentication_provider_id is invalid or inactive")
        return
      end

      DISCOVERY_PAGE_REQUIRED_KEYS.each do |key|
        if entry[key].blank?
          record.errors.add(:settings, "discovery_page.#{section}[#{index}].#{key} is required")
        end
      end

      return unless entry[:icon_url].present?

      begin
        uri = URI.parse(entry[:icon_url])
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          record.errors.add(:settings, "discovery_page.#{section}[#{index}].icon_url must be a valid URL")
        end
      rescue URI::InvalidURIError
        record.errors.add(:settings, "discovery_page.#{section}[#{index}].icon_url must be a valid URL")
      end
    end
  end
end
