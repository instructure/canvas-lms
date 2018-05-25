#
# Copyright (C) 2018 - present Instructure, Inc.
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

ENV["RAILS_ENV"] = ENV["RACK_ENV"]= "test"

require 'pact/provider/rspec'
require_relative '../../../../pact/pact_config'
require_relative '../../../spec_helper'
require_relative 'provider_states_for_consumer'

Pact.service_provider PactConfig::Providers::CANVAS_LMS_API do
  app { CanvasRails::Application }

  pact_path = format(
    'pacts/provider/%<provider>s/consumer/%<consumer>s',
    provider: ERB::Util.url_encode(PactConfig::Providers::CANVAS_LMS_API),
    consumer: ERB::Util.url_encode(PactConfig::Consumers::GENERIC_CONSUMER)
  )

  honours_pact_with PactConfig::Consumers::GENERIC_CONSUMER do

    # pact_uri 'pacts/generic_consumer-canvas_lms_api.json'
    pact_uri PactConfig.pact_uri(pact_path: pact_path)
    app_version PactConfig::Providers::CANVAS_API_VERSION
    publish_verification_results true
  end
end
