/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {enhanceUserContent} from '../instructure'

describe('enhanceUserContent()', () => {
  const subject = bodyHTML => {
    document.body.innerHTML = bodyHTML
    enhanceUserContent()
    return document.body
  }

  describe('when the link has an href and matches a file path', () => {
    const bodyHTML =
      '<a class="instructure_file_link instructure_scribd_file" href="/courses/1/files/1">file</a>'

    it('enhance the link', () => {
      expect(subject(bodyHTML).querySelector('.instructure_file_holder')).toBeInTheDocument()
    })
  })

  describe('when the link has no href attribute', () => {
    const bodyHTML = '<a class="instructure_file_link instructure_scribd_file">file</a>'

    it('does not enhance the link', () => {
      expect(subject(bodyHTML).querySelector('.instructure_file_holder')).not.toBeInTheDocument()
    })
  })
})
