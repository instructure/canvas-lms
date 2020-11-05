# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Importers
  class MissingRequiredToolProfileValuesError < StandardError; end

  class ToolProfileImporter
    class << self
      def process_migration(data, migration)
        tool_profiles = data['tool_profiles'] || []

        tool_profiles.each do |tool_profile|
          begin
            values = tease_out_required_values!(tool_profile)
            next unless migration.import_object?('tool_profiles', tool_profile['migration_id'])

            tool_proxies = Lti::ToolProxy.find_active_proxies_for_context_by_vendor_code_and_product_code(
              context: migration.context,
              vendor_code: values[:vendor_code],
              product_code: values[:product_code]
            )

            if tool_proxies.empty?
              if values[:registration_url].blank?
                migration.add_warning(I18n.t("We were unable to find a tool profile match for \"%{product_name}\".", product_name: values[:product_name]))
              else
                migration.add_warning(I18n.t("We were unable to find a tool profile match for \"%{product_name}\". If you would like to use this tool please install it using the following registration url: %{registration_url}", product_name: values[:product_name], registration_url: values[:registration_url]))
              end
            elsif tool_proxies.none? { |tool_proxy| tool_proxy.matching_tool_profile?(tool_profile['tool_profile']) }
              migration.add_warning(I18n.t("We found a different version of \"%{product_name}\" installed for your course. If this tool fails to work as intended, try reregistering or reinstalling it.", product_name: values[:product_name]))
            end
          rescue MissingRequiredToolProfileValuesError => e
            migration.add_import_warning('tool_profile', tool_profile['resource_href'], e)
          end
        end
      end

      private

      def tease_out_required_values!(tool_profile)
        values = {
          vendor_code: tool_profile.dig('tool_profile', 'product_instance', 'product_info', 'product_family', 'vendor', 'code'),
          product_code: tool_profile.dig('tool_profile', 'product_instance', 'product_info', 'product_family', 'code'),
          registration_url: tool_profile.dig('meta', 'registration_url'),
          product_name: tool_profile.dig('tool_profile', 'product_instance', 'product_info', 'product_name', 'default_value'),
        }

        missing_keys = values.select { |_, v| v.nil? }.keys

        if missing_keys.present?
          fail MissingRequiredToolProfileValuesError, I18n.t("Missing required values: %{missing_values}", missing_values: missing_keys.join(','))
        else
          values
        end
      end
    end
  end
end
