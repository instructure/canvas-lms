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
#
require 'openssl'

module Lti
  class RSAKeyPair < JWKKeyPair
    ALG = 'RS256'.freeze
    SIZE = 2048
    def initialize(use: 'sig')
      @alg = ALG
      @use = use
      @private_key = OpenSSL::PKey::RSA.new SIZE
    end

    def public_key
      private_key.public_key
    end

  end
end
