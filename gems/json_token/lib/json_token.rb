#
# Copyright (C) 2014 Instructure, Inc.
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

require 'json'
require 'base64'

# Convenience methods for encoding and decoding a slug of data into base64
# encoded JSON, e.g. to use in a URL
module JSONToken
  def self.encode(data)
    Base64.encode64(data.to_json).tr('+/', '-_').gsub(/=|\n/, '')
  end

  def self.decode(token)
    json = Base64.decode64(token.tr('-_', '+/').ljust((token.length + 4 - 1) / 4 * 4, '='))
    # JSON.parse requires the thing-to-parse to be an object or array. but we
    # want to be able to parse literal values, too (e.g. strings or integers).
    # so wrap it in an array
    json = JSON.parse("[#{json}]")
    raise JSON::ParserError unless json.size == 1
    return json.first
  end
end
