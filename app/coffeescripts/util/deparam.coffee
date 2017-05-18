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

# an extraction of the deparam method from Ben Alman's jQuery BBQ
# http://benalman.com/projects/jquery-bbq-plugin/

define ['compiled/object/unflatten'], (unflatten) ->

  coerceTypes =
    'true': true
    'false': false
    'null': null

  deparam = (params, coerce) ->
    # shortcut for just deparam'ing the current querystring
    if !params or typeof params == 'boolean'
      currentQueryString = window.location.search
      return {} unless currentQueryString
      return deparam currentQueryString, arguments...

    obj = {}

    params = params.replace(/^\?/, '')
    # Iterate over all name=value pairs.
    for param in params.replace(/\+/g, " ").split("&")
      [key, val] = param.split '='
      key = decodeURIComponent(key)
      val = decodeURIComponent(val)

      # coerce values.
      if coerce
        val = if val && !isNaN(val)
                +val #number
              else if val == 'undefined'
                undefined #undefined
              else if coerceTypes[val] != undefined
                coerceTypes[val] #true, false, null
              else
                val #string

      obj[key] = val

    unflatten obj
