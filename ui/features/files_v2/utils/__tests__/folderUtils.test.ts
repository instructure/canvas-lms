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
import {windowPathname} from '@canvas/util/globalUtils'
import {FAKE_COURSE_FOLDER, FAKE_USER_FOLDER} from '../../fixtures/fakeData'
import {type Folder} from '../../interfaces/File'
import {resetFilesEnv} from '../filesEnvUtils'

jest.mock('@canvas/util/globalUtils', () => ({
  ...jest.requireActual('@canvas/util/globalUtils'),
  windowPathname: jest.fn(),
}))

describe('generateUrlPath', () => {
  let courseFolder: Folder, userFolder: Folder

  beforeEach(() => {
    courseFolder = FAKE_COURSE_FOLDER
    userFolder = FAKE_USER_FOLDER
  })

  describe('when showing all contexts', () => {
    beforeAll(() => {
      ;(windowPathname as jest.Mock).mockReturnValue('/files/')
    })

    afterAll(() => {
      resetFilesEnv()
      jest.resetAllMocks()
    })

    it('returns the correct path for a course folder', () => {
      const path = generateUrlPath(courseFolder)
      expect(path).toBe('/folder/courses_1/2nd%20Folder/A%20Fake%20Course%20Folder')
    })

    it('returns the correct path fo ra user folder', () => {
      const path = generateUrlPath(userFolder)
      expect(path).toBe('/folder/users_1/2nd%20Folder/A%20Fake%20Course%20Folder')
    })
  })

  describe('when not showing all contexts', () => {
    beforeAll(() => {
      ;(windowPathname as jest.Mock).mockReturnValue('/')
    })

    afterAll(() => {
      resetFilesEnv()
      jest.resetAllMocks()
    })

    it('returns the correct path for a course folder', () => {
      const path = generateUrlPath(courseFolder)
      expect(path).toBe('/folder/2nd%20Folder/A%20Fake%20Course%20Folder')
    })
  })
})
