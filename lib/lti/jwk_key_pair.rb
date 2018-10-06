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
module Lti
  class JWKKeyPair
    attr_reader :public_key, :private_key, :alg, :use
    def to_jwk
      private_key.to_jwk(kid: kid, alg: alg, use: use)
    end

    def public_jwk
      private_key.public_key.to_jwk(kid: kid, alg: alg, use: use)
    end

    private

    def kid
      @_kid ||= Time.now.utc.iso8601
    end
  end
end
