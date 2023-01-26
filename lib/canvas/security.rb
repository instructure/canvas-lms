# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "canvas_security"

module Canvas
  # temporary shim rather than replacing all callsites at once
  # TODO: remove references to Canvas::Security through the Canvas app
  # individually, and then remove this file.
  module Security
    # normally we would alias Security to be CanvasSecurity
    # as the shim, but we have several other classes actually inside
    # lib/canvas/security/*.rb that need the existing module structure,
    # so method_missing works better at the moment.
    class << self
      def method_missing(...)
        CanvasSecurity.send(...)
      end
    end

    InvalidToken = CanvasSecurity::InvalidToken
    TokenExpired = CanvasSecurity::AuthenticationError
    InvalidJwtKey = CanvasSecurity::InvalidJwtKey
  end
end
