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

import {
  generateFolderByPathUrl,
  generateFilesQuotaUrl,
  generateFolderPostUrl,
  parseLinkHeader,
} from '../apiUtils'
import {setupFilesEnv} from '../../fixtures/fakeFilesEnv'

describe('generateFolderByPathUrl', () => {
  describe('when showing all contexts', () => {
    beforeAll(() => {
      setupFilesEnv(true)
    })

    it('returns correct url for user subfolder', () => {
      const url = generateFolderByPathUrl('/users_1/profile pictures')
      expect(url).toBe('/api/v1/users/1/folders/by_path/profile%20pictures')
    })

    it('returns correct url for course subfolder', () => {
      const url = generateFolderByPathUrl('/courses_1/afolder/asubfolder')
      expect(url).toBe('/api/v1/courses/1/folders/by_path/afolder/asubfolder')
    })

    it('returns the correct url when folder has uri characters', () => {
      const url = generateFolderByPathUrl('/courses_1/some folder/this#could+be bad?maybe')
      expect(url).toBe(
        '/api/v1/courses/1/folders/by_path/some%20folder/this%23could%2Bbe%20bad%3Fmaybe',
      )
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

    it('returns the correct url when folder has uri characters', () => {
      const url = generateFolderByPathUrl('/this#could+be bad?maybe')
      expect(url).toBe('/api/v1/courses/1/folders/by_path/this%23could%2Bbe%20bad%3Fmaybe')
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

describe('generateFolderPostUrl', () => {
  it('returns correct url', () => {
    const url = generateFolderPostUrl('1')
    expect(url).toBe('/api/v1/folders/1/folders')
  })
})

describe('parseLinkHeader', () => {
  it('returns empty object for null header', () => {
    const links = parseLinkHeader(null)
    expect(links).toEqual({})
  })

  it('returns current, next, and last links', () => {
    const header = '</current>; rel="current", </next>; rel="next", </last>; rel="last"'
    const links = parseLinkHeader(header)
    expect(links).toEqual({current: '/current', next: '/next', last: '/last'})
  })
})
