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

import {generateFolderByPathUrl, generateFilesQuotaUrl} from '../apiUtils'
import {setupFilesEnv} from '../../fixtures/fakeFilesEnv'

describe('generateFolderByPathUrl', () => {
  describe('when showing all contexts', () => {
    beforeAll(() => {
      setupFilesEnv(true)
    })

    it('returns correct url for user subfolder', () => {
      const url = generateFolderByPathUrl('/users_1/profile pictures')
      expect(url).toBe('/api/v1/users/1/folders/by_path/profile pictures')
    })

    it('returns correct url for course subfolder', () => {
      const url = generateFolderByPathUrl('/courses_1/afolder/asubfolder')
      expect(url).toBe('/api/v1/courses/1/folders/by_path/afolder/asubfolder')
    })
  })

  describe('when showing only course context', () => {
    beforeAll(() => {
      setupFilesEnv(false)
    })

    it('returns correct url for course subfolder', () => {
      const url = generateFolderByPathUrl('/afolder/asubfolder')
      expect(url).toBe('/api/v1/courses/1/folders/by_path/afolder/asubfolder')
    })
  })
})

describe('generateFilesQuotaUrl', () => {
  it('returns correct url for user context', () => {
    const url = generateFilesQuotaUrl('user', '1')
    expect(url).toBe('/api/v1/users/1/files/quota')
  })

  it('returns correct url for course context', () => {
    const url = generateFilesQuotaUrl('course', '1')
    expect(url).toBe('/api/v1/courses/1/files/quota')
  })
})
