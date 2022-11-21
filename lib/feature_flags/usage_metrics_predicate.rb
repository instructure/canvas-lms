# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module FeatureFlags
  class UsageMetricsPredicate
    def initialize(context)
      @context = context
    end

    def call
      overridden? || (us_billing_code? && domestic_territory?)
    end

    private

    def overridden?
      @context&.root_account&.settings&.[](:enable_usage_metrics)
    end

    def us_billing_code?
      verify_external_integration? "salesforce_billing_country_code", "US"
    end

    # Calling out here that `key_type: "salesforce_territory_region")&.key_value == "domestic"`
    #   is totally made up right now and won't resolve anything until we add salesforce
    #   data with these values
    def domestic_territory?
      verify_external_integration? "salesforce_territory_region", "domestic"
    end

    def verify_external_integration?(key, value)
      @context&.root_account&.external_integration_keys&.find_by(key_type: key)&.key_value == value
    end
  end
end
