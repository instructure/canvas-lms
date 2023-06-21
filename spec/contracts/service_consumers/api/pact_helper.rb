# frozen_string_literal: true

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

ENV["RAILS_ENV"] = ENV["RACK_ENV"] = "test"

require "pact/provider/rspec"
require_relative "../pact_config"
require_relative "../../../spec_helper"
require_relative "pact_setup"
require_relative "proxy_app"
require_relative "provider_states_for_consumer"

Pact.service_provider PactConfig::Providers::CANVAS_LMS_API do
  app { PactApiConsumerProxy.new }

  def provider_verification_for(consumer)
    pact_path =
      format(
        "pacts/provider/%<provider>s/consumer/%<consumer>s",
        provider: ERB::Util.url_encode(PactConfig::Providers::CANVAS_LMS_API),
        consumer: ERB::Util.url_encode(consumer)
      )

    honours_pact_with consumer do
      pact_uri PactConfig.pact_uri(pact_path:)
      app_version PactConfig::Providers::CANVAS_API_VERSION
      publish_verification_results true
    end
  end

  # Specify and run a single consumer
  # or have the option to run Pact verification for all consumers
  PactConfig::Consumers::ALL.each do |consumer|
    next if consumer == PactConfig::Consumers::CANVAS_LMS_API # don't want to run canvas-lms contracts against itself where it would be a consumer and provider

    if (ENV["PACT_API_CONSUMER"].present? && ENV["PACT_API_CONSUMER"] == consumer) ||
       ENV["PACT_API_CONSUMER"].blank?
      provider_verification_for(consumer)
    end
  end
end
