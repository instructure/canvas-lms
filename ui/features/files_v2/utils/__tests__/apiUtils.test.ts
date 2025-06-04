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
  parseBookmarkFromUrl,
  generateTableUrl,
  generateSearchNavigationUrl,
} from '../apiUtils'
import {resetAndGetFilesEnv} from '../filesEnvUtils'
import {createFilesContexts} from '../../fixtures/fileContexts'
import {windowPathname} from '@canvas/util/globalUtils'

jest.mock('@canvas/util/globalUtils', () => ({
  windowPathname: jest.fn(),
}))

describe('generateFolderByPathUrl', () => {
  const expectedPluralContextType = 'courses'
  const expectedContextId = '1'

  it('returns correct url when no path is given', () => {
    const url = generateFolderByPathUrl(expectedPluralContextType, expectedContextId)
    expect(url).toBe(`/api/v1/${expectedPluralContextType}/${expectedContextId}/folders/by_path`)
  })

  it('returns correct url for subfolder', () => {
    const path = 'afolder/asubfolder'
    const expectedPath = 'afolder/asubfolder'
    const url = generateFolderByPathUrl(expectedPluralContextType, expectedContextId, path)
    expect(url).toBe(
      `/api/v1/${expectedPluralContextType}/${expectedContextId}/folders/by_path/${expectedPath}`,
    )
  })

  it('returns the correct url when path has uri characters', () => {
    const path = 'some folder/this#could+be bad?maybe'
    const expectedPath = 'some%20folder/this%23could%2Bbe%20bad%3Fmaybe'
    const url = generateFolderByPathUrl(expectedPluralContextType, expectedContextId, path)
    expect(url).toBe(
      `/api/v1/${expectedPluralContextType}/${expectedContextId}/folders/by_path/${expectedPath}`,
    )
  })

  it('returns the correct url when path includes % character', () => {
    // some folder/this%could+be bad?maybe
    // % character is encoded as &#37; in html
    const path = 'some folder/this&#37;could+be bad?maybe'
    const expectedPath = 'some%20folder/this%25could%2Bbe%20bad%3Fmaybe'
    const url = generateFolderByPathUrl(expectedPluralContextType, expectedContextId, path)
    expect(url).toBe(
      `/api/v1/${expectedPluralContextType}/${expectedContextId}/folders/by_path/${expectedPath}`,
    )
  })

  it('returns the correct url when path includes multiple % characters', () => {
    // folder name = %%
    // % character is encoded as &#37; in html
    const path = '&#37;&#37;'
    const expectedPath = '%25%25'
    const url = generateFolderByPathUrl(expectedPluralContextType, expectedContextId, path)
    expect(url).toBe(
      `/api/v1/${expectedPluralContextType}/${expectedContextId}/folders/by_path/${expectedPath}`,
    )
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

describe('generateTableUrl', () => {
  const QUERY_PARAMS =
    'per_page=25&include[]=user&include[]=usage_rights&include[]=enhanced_preview_url&include[]=context_asset_string&include[]=blueprint_course_status'

  it('returns correct url for search when course', () => {
    const url = generateTableUrl({
      searchTerm: 'search',
      contextType: 'course',
      contextId: '1',
      folderId: '2',
      sortBy: 'name',
      sortDirection: 'asc',
      pageQueryParam: 'bookmark:foobarbaz',
    })
    expect(url).toBe(
      `/api/v1/courses/1/files?search_term=search&${QUERY_PARAMS}&sort=name&order=asc&page=bookmark:foobarbaz`,
    )
  })

  it('returns correct url for search when user', () => {
    const url = generateTableUrl({
      searchTerm: 'search',
      contextType: 'user',
      contextId: '1',
      folderId: '2',
      sortBy: 'name',
      sortDirection: 'desc',
      pageQueryParam: 'bookmark:foobarbaz',
    })
    expect(url).toBe(
      `/api/v1/users/1/files?search_term=search&${QUERY_PARAMS}&sort=name&order=desc&page=bookmark:foobarbaz`,
    )
  })

  it('returns correct url for search when group', () => {
    const url = generateTableUrl({
      searchTerm: 'search',
      contextType: 'group',
      contextId: '1',
      folderId: '2',
      sortBy: 'name',
      sortDirection: 'asc',
      pageQueryParam: 'bookmark:foobarbaz',
    })
    expect(url).toBe(
      `/api/v1/groups/1/files?search_term=search&${QUERY_PARAMS}&sort=name&order=asc&page=bookmark:foobarbaz`,
    )
  })

  it('returns correct url for search when no page query param', () => {
    const url = generateTableUrl({
      searchTerm: 'search',
      contextType: 'course',
      contextId: '1',
      folderId: '2',
      sortBy: 'name',
      sortDirection: 'desc',
    })
    expect(url).toBe(
      `/api/v1/courses/1/files?search_term=search&${QUERY_PARAMS}&sort=name&order=desc`,
    )
  })

  it('returns correct url for fetch all', () => {
    const url = generateTableUrl({
      searchTerm: '',
      contextType: 'course',
      contextId: '1',
      folderId: '2',
      sortBy: 'name',
      sortDirection: 'asc',
      pageQueryParam: 'bookmark:foobarbaz',
    })
    expect(url).toBe(
      `/api/v1/folders/2/all?${QUERY_PARAMS}&sort=name&order=asc&page=bookmark:foobarbaz`,
    )
  })

  it('returns correct url for fetch all when no page query param', () => {
    const url = generateTableUrl({
      searchTerm: '',
      contextType: 'course',
      contextId: '1',
      folderId: '2',
      sortBy: 'name',
      sortDirection: 'desc',
    })
    expect(url).toBe(`/api/v1/folders/2/all?${QUERY_PARAMS}&sort=name&order=desc`)
  })
})

describe('generateSearchNavigationUrl', () => {
  it('returns correct url when showing all contexts', () => {
    const filesContexts = createFilesContexts({
      isMultipleContexts: true,
    })
    ;(windowPathname as jest.Mock).mockReturnValue('/files/folder/users_1')
    resetAndGetFilesEnv(filesContexts)

    const url = generateSearchNavigationUrl('foo')
    expect(url).toBe('/folder/users_1?search_term=foo')
  })

  it('returns correct url when showing only course context', () => {
    const filesContexts = createFilesContexts()
    ;(windowPathname as jest.Mock).mockReturnValue('/')
    resetAndGetFilesEnv(filesContexts)

    const url = generateSearchNavigationUrl('foo')
    expect(url).toBe('/?search_term=foo')
  })
})

describe('parseBookmarkFromUrl', () => {
  it('return null for undefined', () => {
    const bookmark = parseBookmarkFromUrl(undefined)
    expect(bookmark).toBe(null)
  })

  it('return null for invalid url', () => {
    const bookmark = parseBookmarkFromUrl('invalid-url')
    expect(bookmark).toBe(null)
  })

  it('return null for valid url without page param', () => {
    const bookmark = parseBookmarkFromUrl('http://example.com')
    expect(bookmark).toBe(null)
  })

  it('return page param for valid url with page param', () => {
    const bookmark = parseBookmarkFromUrl('http://example.com?page=2')
    expect(bookmark).toBe('2')
  })
})
