# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'pact/consumer/rspec'
require_relative '../service_consumers/pact_config'
require_relative '../../spec_helper'

Pact.configure do |config|
  config.pact_dir = File.expand_path('pacts')
end

Pact.service_consumer PactConfig::Consumers::CANVAS_LMS_API do
  has_pact_with PactConfig::Providers::OUTCOMES do
    mock_service :outcomes do
      port 1234
      pact_specification_version '2.0.0'
    end
  end
end

RSpec.configure do |config|
  config.before(:context, :pact) do
    WebMock.disable_net_connect!(allow: ['localhost'])
  end
  config.after(:context, :pact) do
    WebMock.enable_net_connect!
  end
end
