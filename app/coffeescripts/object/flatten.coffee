#
# Copyright (C) 2012 - present Instructure, Inc.
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

# turns {foo: {bar: 1}} into {'foo[bar]': 1}
define ->
  flatten = (obj, options = {}, result = {}, prefix) ->
    for key, value of obj
      key = if prefix then "#{prefix}[#{key}]" else key
      flattenable = (typeof value is 'object')
      flattenable = false if value.length? and options.arrays is false
      if flattenable
        flatten(value, options, result, key)
      else
        result[key] = value
    result