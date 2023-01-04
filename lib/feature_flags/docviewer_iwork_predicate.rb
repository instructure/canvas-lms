# frozen_string_literal: true

#
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
#

# This was copied from usage_metrics_predicate as the requirements are the same right now. This might not always be
# true, so this was recreated in a separate file.
#
# Right now Apple only has a server in the US, to comply with GDPR, we'll only turn this on for folks in the US.
module FeatureFlags
  class DocviewerIworkPredicate
    def initialize(context, region)
      @context = context
      @region = region
    end

    def call
      overridden? || (us_billing_code? && in_approved_us_aws_region?)
    end

    private

    def overridden?
      @context&.root_account&.settings&.[](:docviewer_enable_iwork_files)
    end

    def us_billing_code?
      @context&.root_account&.external_integration_keys&.find_by(key_type: "salesforce_billing_country_code")&.key_value == "US"
    end

    def in_approved_us_aws_region?
      ["us-east-1", "us-west-2"].include? @region
    end
  end
end
