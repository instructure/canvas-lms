#
# Copyright (C) 2015 - present Instructure, Inc.
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

define ->
  ToObject = (val) ->
    if val == null
      throw new TypeError('Object.assign cannot be called with null or undefined')
    Object val

  'use strict'
  ObjectAssign = Object.assign or (target, source) ->
    from = undefined
    keys = undefined
    to = ToObject(target)
    s = 1
    while s < arguments.length
      from = arguments[s]
      keys = Object.keys(Object(from))
      i = 0
      while i < keys.length
        to[keys[i]] = from[keys[i]]
        i++
      s++
    to
