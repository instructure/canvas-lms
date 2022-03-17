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

RSpec.describe SecurityController, type: :request do
  # This uses the lti keyset, but it doesn't really matter which one
  let(:url) { Rails.application.routes.url_helpers.jwks_show_path }
  let(:json) { JSON.parse(response.body) }

  let(:past_key) { CanvasSecurity::KeyStorage.new_key }
  let(:present_key) { CanvasSecurity::KeyStorage.new_key }
  let(:future_key) { CanvasSecurity::KeyStorage.new_key }

  let(:fallback_proxy) do
    DynamicSettings::FallbackProxy.new(
      CanvasSecurity::KeyStorage::PAST => past_key,
      CanvasSecurity::KeyStorage::PRESENT => present_key,
      CanvasSecurity::KeyStorage::FUTURE => future_key
    )
  end

  around do |example|
    Timecop.freeze { example.run }
  end

  before do
    allow(DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
  end

  it "returns ok status" do
    get url
    expect(response).to have_http_status :ok
  end

  it "returns a jwk set" do
    get url
    expect(json["keys"]).not_to be_empty
  end

  it "sets the Cache-control header" do
    get url
    expect(response.headers["Cache-Control"]).to include "max-age=864000"
  end

  it "returns well-formed public key jwks" do
    get url
    expected_keys = %w[kid kty alg e n use]
    json["keys"].each do |key|
      expect(key.keys - expected_keys).to be_empty
    end
  end

  context "with ?rotation_check=1" do
    let(:past_key) { Timecop.travel(1.month.ago) { CanvasSecurity::KeyStorage.new_key } }
    let(:future_key) { Timecop.travel(1.month.from_now) { CanvasSecurity::KeyStorage.new_key } }

    it "returns whether each key is from the current month" do
      # This is memoized, so make sure we get the new one we make in this test
      expect(Lti::KeyStorage).to receive(:consul_proxy).at_least(:once).and_return(fallback_proxy)

      day = Time.zone.now.utc.to_date.day
      get url, params: { rotation_check: "1" }
      expect(json).to eq([
                           "today is day #{day} and key 0 is not from this month",
                           "today is day #{day} and key 1 is from this month",
                           "today is day #{day} and key 2 is not from this month"
                         ])
    end
  end
end
