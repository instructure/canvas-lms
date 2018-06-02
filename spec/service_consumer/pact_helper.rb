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
require_relative '../spec_helper'
require 'pact/provider/rspec'
require 'database_cleaner'

# Require the provider states files for each service consumer
require_relative 'provider_states_for_consumer'

Pact.service_provider "CanvasAPI" do
  # Optional app configuration. Pact loads the app from config.ru by default
  # (it is recommended to let Pact use the config.ru if possible, so testing
  # conditions are closest to runtime conditions)
  app { CanvasRails::Application }

  honours_pact_with 'Consumer' do

    # This example points to a local file, however, on a real project with a continuous
    # integration box, you would publish your pacts as artifacts,
    # and point the pact_uri to the pact published by the last successful build.

    pact_uri 'spec/pacts/consumer-canvasapi.json'
  end

  # This block is repeated for every pact that this provider should be verified against.
  #  honours_pact_with 'Some other Service Consumer' do
  #    ...
  #  end

end
