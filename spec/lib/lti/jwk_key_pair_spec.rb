#
# Copyright (C) 2016 - present Instructure, Inc.
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
require 'timecop'
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Lti::JWKKeyPair do
  describe "to_jwk" do
    it 'has the private key in the JWK format' do
      Timecop.freeze(Time.zone.now) do
        keys = Lti::RSAKeyPair.new
        expect(keys.to_jwk).to include(keys.private_key.to_jwk(kid: Time.now.utc.iso8601))
      end
    end
  end
end
