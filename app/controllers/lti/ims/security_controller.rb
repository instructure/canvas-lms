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

module Lti::Ims
  # @API Security
  # @internal
  #
  # TODO: remove internal flags
  #
  # Security api for IMS LTI 1.3.
  #
  # @model JWKs
  #  {
  #    "id": "JWKs",
  #    "description": "",
  #    "properties": {
  #      "keys": {
  #        "description": "The set of JWK objects avaiable to verify JWS signature."
  #        "type": "array",
  #        "items": {
  #          "kty": "string"
  #          "kid": "string",
  #          "alg": "string"
  #        },
  #        "example": ["{\"kty\":\"RSA\",\"n\":\"0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx\\n      4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMs\\n      tn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2\\n      QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbI\\n      SD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqb\\n      w0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw\",\"e\":\"AQAB\",\"alg\":\"RS256\",\"kid\":\"2011-04-29\"}"]
  #      }
  #    }
  #   }
  #
  class SecurityController < ApplicationController
    skip_before_action :load_user

    # @API Show all available JWKs used by Canvas for signing.
    #
    # @returns JWKs
    def jwks
      keys = Lti::KeyStorage.public_keyset
      render json: { keys: keys }
    end
  end
end
