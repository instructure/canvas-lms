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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require_dependency "lti/ims/security_controller"

module Lti::Ims
  RSpec.describe SecurityController, type: :request do
    before do
      allow(Canvas::DynamicSettings).to receive(:find).
        with(any_args).and_call_original
      allow(Canvas::DynamicSettings).to receive(:find).
        with('lti').and_return(jwk_set)
    end

    let(:url) { Rails.application.routes.url_helpers.jwks_show_path }
    let(:jwk) do
     {
        "kty"=>"RSA",
        "e"=>"AQAB",
        "n"=>"uX1MpfEMQCBUMcj0sBYI-iFaG5Nodp3C6OlN8uY60fa5zSBd83-iIL3n_qzZ8VCluuTLfB7rrV_tiX727XIEqQ",
        "kid"=>"2018-06-18T22:33:20Z",
        "d"=>"pYwR64x-LYFtA13iHIIeEvfPTws50ZutyGfpHN-kIZz3k-xVpun2Hgu0hVKZMxcZJ9DkG8UZPqD-zTDbCmCyLQ",
        "p"=>"6OQ2bi_oY5fE9KfQOcxkmNhxDnIKObKb6TVYqOOz2JM",
        "q"=>"y-UBef95njOrqMAxJH1QPds3ltYWr8QgGgccmcATH1M",
        "dp"=>"Ol_xkL7rZgNFt_lURRiJYpJmDDPjgkDVuafIeFTS4Ic",
        "dq"=>"RtzDY5wXr5TzrwWEztLCpYzfyAuF_PZj1cfs976apsM",
        "qi"=>"XA5wnwIrwe5MwXpaBijZsGhKJoypZProt47aVCtWtPE"
      }.to_json
    end
    let(:jwk_set) { { 'past' => jwk, 'present' => jwk, 'future' => jwk } }
    let(:json) { JSON.parse(response.body) }

    it 'returns ok status' do
      get url
      expect(response).to have_http_status :ok
    end

    it 'returns a jwk set' do
      get url
      expect(json['keys']).not_to be_empty
    end

    it 'returns well-formed public key jwks' do
      get url
      expected_keys = %w(kid kty alg e n)
      json['keys'].each do |key|
        expect(key.keys - expected_keys).to be_empty
      end
    end
  end
end
