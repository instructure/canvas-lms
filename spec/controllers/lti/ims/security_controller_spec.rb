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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lti_1_3_spec_helper')

require_dependency "lti/ims/security_controller"

module Lti::Ims
  RSpec.describe SecurityController, type: :request do
    include_context 'lti_1_3_spec_helper'

    let(:url) { Rails.application.routes.url_helpers.jwks_show_path }
    let(:json) { JSON.parse(response.body) }

    it 'returns ok status' do
      get url
      expect(response).to have_http_status :ok
    end

    it 'returns a jwk set' do
      get url
      expect(json['keys']).not_to be_empty
    end

    it 'sets the Cache-control header' do
      get url
      expect(response.headers['Cache-Control']).to include 'max-age=864000'
    end

    it 'returns well-formed public key jwks' do
      get url
      expected_keys = %w(kid kty alg e n use)
      json['keys'].each do |key|
        expect(key.keys - expected_keys).to be_empty
      end
    end
  end
end
