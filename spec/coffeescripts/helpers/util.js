#
# Copyright (C) 2013 - present Instructure, Inc.
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

define ['jquery', 'underscore'], ($, _) ->

  closeDialog: ->
    $('.ui-dialog-content').dialog 'close'

  useOldDebounce: ->
    # this version of debounce works with sinon's useFakeTimers
    _.debounce = (func, wait, immediate) ->
      return ->
        context = this
        args = arguments
        timestamp = new Date()
        later = ->
          last = (new Date()) - timestamp
          if (last < wait)
            timeout = setTimeout(later, wait - last)
           else
            timeout = null
            result = func.apply(context, args) unless immediate
        callNow = immediate && !timeout
        timeout = setTimeout(later, wait) unless timeout
        result = func.apply(context, args) if callNow
        return result

  debounce: _.debounce

  useNormalDebounce: ->
    _.debounce = @debounce
