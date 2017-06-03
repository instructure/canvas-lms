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

define [
  'jquery'
  'underscore',
  'compiled/util/rgb2hex'
], ($, _, rgb2hex) ->
  ContextColorer = {
    persistContextColors: (colorsByContext, userId) ->
      _.each(colorsByContext, (color, contextCode) ->
        if contextCode.match(/course/)
          if color.match(/rgb/)
            hexcodeColor = rgb2hex(color)
          else
            hexcodeColor = color

          $.ajax({
            url: '/api/v1/users/' + userId + '/colors/' + contextCode,
            type: 'PUT',
            data: { hexcode: hexcodeColor}
          })
      )
  }
