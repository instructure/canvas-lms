# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe PageViews::Configuration do
  let(:pv5_creds) { { test: { access_token: "mock_access_token" } } }

  before do
    allow(ConfigFile).to receive(:load).with("pv5").and_return("uri" => "http://pv5.instructure.com")
    allow(Rails.env).to receive(:to_sym).and_return(:test)
    allow(Rails.application.credentials).to receive(:pv5_creds).and_return(pv5_creds)
  end

  after do
    RSpec::Mocks.space.proxy_for(Rails.env).reset
    RSpec::Mocks.space.proxy_for(ConfigFile).reset
    RSpec::Mocks.space.proxy_for(Rails.application.credentials).reset
  end

  it "loads configuration and secrets properly" do
    config = PageViews::Configuration.new
    expect(config.access_token).to eq("mock_access_token")
    expect(config.uri).to be_a(URI::HTTP)
    expect(config.uri.to_s).to eq("http://pv5.instructure.com")
  end
end
