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
#

# NOTE: If you are looking for a way to add custom parameters or change LTI 1.1
# tool settings in bulk, there is an easier way written after this fixup. See
# DataFixup::BulkToolUpdater in instructure_misc_plugin (run
# `DataFixup::BulkToolUpdater.help` in Rails console for help)

module DataFixup::Lti::UpdateCustomParams
  LOGGER_PREFIX = "Lti::UpdateCustomParams => "

  # This script will update all specified instances of LTI tools within Canvas,
  # it is intended to be copied and pasted into a Canvas console
  #
  # e.g. DataFixup::Lti::UpdateCustomParams.run!(
  #   ['your-lti-url1', 'your-lti-url2', '\w\.?.instructure.com'], # REGEX allowed for vanity support
  #   {"high_contrast" => "$Canvas.user.prefersHighContrast"},
  #   subdomain_matching: true, # default value and optional
  #   validate_domain: true # default value and optional stuff
  # )
  #
  # Dry run: DataFixup::Lti::UpdateCustomParams.search(['your-lti-url1']) { |tool| p tool.domain }
  #
  # Example custom_fields:
  # {
  #   "high_contrast" => "$Canvas.user.prefersHighContrast",
  #   "masquerading_user_id" => "$Canvas.masqueradingUser.userId",
  #   "canvas_user_id" => "$Canvas.user.id"
  # }

  class << self
    def run!(domains, custom_fields, subdomain_matching: true, validate_domain: true)
      failures = []

      search(domains, subdomain_matching, validate_domain) do |tool|
        tool.settings = Importers::ContextExternalToolImporter.create_tool_settings({
                                                                                      settings: tool.settings.deep_merge({
                                                                                                                           "custom_fields" => custom_fields
                                                                                                                         })
                                                                                    })

        return failures << tool unless tool.save

        logger "Successfully migrated tool @ #{tool.url} !"
      end

      logger "Total failed migrations: #{failures.count}"
      failures
    end

    def search(domains, subdomain_matching, validate_domain, &)
      validate_domains!(domains) if validate_domain
      Switchman::Shard.with_each_shard do
        select_by_domains(domains, subdomain_matching).find_each(&)
      end
    end

    def logger(msg)
      Rails.logger.info LOGGER_PREFIX + msg
    end

    def validate_domains!(domains)
      domains.grep(/\A[\w.-]*\z/)
    end

    def select_by_domains(domains, subdomain_matching)
      # we allow one \w*. before the provided domain
      subdomain_match = subdomain_matching ? "(\\w*\\.)?" : ""

      ContextExternalTool.active.where(
        '"context_external_tools".url ~ ANY (array[?])', domains.map { |d| "^https?://#{subdomain_match}#{d}/" }
      )
    end
  end
end
