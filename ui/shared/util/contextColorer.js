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

import {each} from 'lodash'
import rgb2hex from './rgb2hex'
import {defaultFetchOptions} from './xhr'

export default {
  persistContextColors(colorsByContext, userId) {
    each(colorsByContext, (color, contextCode) => {
      const hexcode = (color.match(/rgb/) ? rgb2hex(color) : color).replace(/^#/, '')

      // I don't know why, but when the hexcode was in the body, it failed to
      // work from selenium
      const url = `${window.location.origin}/api/v1/users/${userId}/colors/${contextCode}?hexcode=${hexcode}`
      fetch(url, {
        method: 'PUT',
        ...defaultFetchOptions(),
      })
    })
  },
}
