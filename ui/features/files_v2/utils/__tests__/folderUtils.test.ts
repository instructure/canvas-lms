/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {generateUrlPath} from '../folderUtils'
import {FAKE_FOLDERS} from '../../fixtures/fakeData'
import {type Folder} from '../../interfaces/File'

describe('generateUrlPath', () => {
  let folder: Folder
  beforeEach(() => {
    folder = FAKE_FOLDERS[0]
  })

  describe('when not showing all contexts', () => {
    it('returns the correct path for a course folder', () => {
      folder.full_name = 'course files/asdf/asdf2'
      const path = generateUrlPath(folder)
      expect(path).toBe('/folder/asdf/asdf2')
    })

    it('returns the correct path for a course folder with spaces', () => {
      folder.full_name = 'course files/Uploaded Media'
      const path = generateUrlPath(folder)
      expect(path).toBe('/folder/Uploaded%20Media')
    })
  })
})
