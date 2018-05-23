//
// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import _ from 'underscore'
import rgb2hex from './util/rgb2hex'

export default {
  persistContextColors (colorsByContext, userId) {
    _.each(colorsByContext, (color, contextCode) => {
      const hexcode = color.match(/rgb/) ? rgb2hex(color) : color

      const url = `/api/v1/users/${userId}/colors/${contextCode}`
      $.ajax({url, type: 'PUT', data: {hexcode}})
    })
  }
}
