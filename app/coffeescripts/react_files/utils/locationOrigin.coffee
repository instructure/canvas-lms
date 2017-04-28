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

define [], () ->
  # locationOrigin.coffee
  #
  # A slight modification of location-origin.js
  # https://github.com/shinnn/location-origin.js
  'use strict'

  loc = window.location

  return if loc.origin

  value = loc.protocol + '//' + loc.hostname + if loc.port then ':' + loc.port else ''

  try
    Object.defineProperty loc, 'origin', {value, enumerable: true}
  catch e
    loc.origin = value