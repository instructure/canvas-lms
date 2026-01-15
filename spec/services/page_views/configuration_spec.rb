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
  before do
    allow(ConfigFile).to receive(:load).with("pv5").and_return("uri" => "http://pv5.instructure.com")
  end

  after do
    RSpec::Mocks.space.proxy_for(ConfigFile).reset
  end

  it "loads configuration properly" do
    config = PageViews::Configuration.new
    expect(config.uri).to be_a(URI::HTTP)
    expect(config.uri.to_s).to eq("http://pv5.instructure.com")
  end
end
