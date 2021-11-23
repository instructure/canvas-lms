# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module HmacHelper
  # returns parsed json after verification
  def extract_blob(hmac, json, expected_values = {})
    unless Canvas::Security.verify_hmac_sha1(hmac, json)
      raise Error.new("signature doesn't match.")
    end

    blob = JSON.parse(json)

    expected_values.each { |k, v|
      raise Error.new("invalid value for #{k}") if blob[k] != v
    }

    blob
  end

  class Error < StandardError; end
end
