# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# @API Security
# @internal
#
# TODO fill in the properties
# @model JWKs
#  {
#    "id": "JWKs",
#    "description": "",
#    "properties": {
#    }
#  }
#
class SecurityController < ApplicationController
  # @API Show all available JWKs used by Canvas for signing.
  #
  # @returns JWKs
  def jwks
    key_storage = case request.path
                  when "/internal/services/jwks"
                    CanvasSecurity::ServicesJwt::KeyStorage
                  when "/login/oauth2/jwks"
                    Canvas::OAuth::KeyStorage
                  when "/api/lti/security/jwks"
                    Lti::KeyStorage
                  end
    public_keyset = key_storage.public_keyset

    if params.include?(:rotation_check)
      today = Time.zone.now.utc.to_date
      reports = public_keyset.as_json[:keys].each_with_index.map do |key, i|
        date = CanvasSecurity::JWKKeyPair.time_from_kid(key[:kid]).utc.to_date
        this_month = [today.year, today.month] == [date.year, date.month]
        "today is day #{today.day} and key #{i} is #{this_month ? "" : "not "}from this month"
      end
      render json: reports
    else
      response.set_header("Cache-Control", "max-age=#{key_storage.max_cache_age}")
      render json: public_keyset
    end
  end
end
