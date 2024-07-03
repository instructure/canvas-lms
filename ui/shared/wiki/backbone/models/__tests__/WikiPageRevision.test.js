/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import WikiPage from '../WikiPage'
import WikiPageRevision from '../WikiPageRevision'
import '@canvas/jquery/jquery.ajaxJSON'

describe('WikiPageRevision', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    jest.resetModules()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('urls', () => {
    test('captures contextAssetString, page, pageUrl, latest, and summary as constructor options', () => {
      const page = new WikiPage()
      const revision = new WikiPageRevision(
        {},
        {
          contextAssetString: 'course_73',
          page,
          pageUrl: 'page-url',
          latest: true,
          summary: true,
        }
      )
      expect(revision.contextAssetString).toBe('course_73')
      expect(revision.page).toBe(page)
      expect(revision.pageUrl).toBe('page-url')
      expect(revision.latest).toBe(true)
      expect(revision.summary).toBe(true)
    })

    test('urlRoot uses the context path and pageUrl', () => {
      const revision = new WikiPageRevision(
        {},
        {
          contextAssetString: 'course_73',
          pageUrl: 'page-url',
        }
      )
      expect(revision.urlRoot()).toBe('/api/v1/courses/73/pages/page-url/revisions')
    })

    test('url returns urlRoot if latest and id are not specified', () => {
      const revision = new WikiPageRevision(
        {},
        {
          contextAssetString: 'course_73',
          pageUrl: 'page-url',
        }
      )
      expect(revision.url()).toBe('/api/v1/courses/73/pages/page-url/revisions')
    })

    test('url is affected by the revision_id attribute', () => {
      const revision = new WikiPageRevision(
        {revision_id: 42},
        {
          contextAssetString: 'course_73',
          pageUrl: 'page-url',
        }
      )
      expect(revision.url()).toBe('/api/v1/courses/73/pages/page-url/revisions/42')
    })

    test('url is affected by the latest flag', () => {
      const revision = new WikiPageRevision(
        {revision_id: 42},
        {
          contextAssetString: 'course_73',
          pageUrl: 'page-url',
          latest: true,
        }
      )
      expect(revision.url()).toBe('/api/v1/courses/73/pages/page-url/revisions/latest')
    })
  })

  describe('parse', () => {
    beforeEach(() => {
      jest.spyOn($, 'ajaxJSON').mockImplementation(() => {
        return {
          done: jest.fn().mockReturnThis(),
          fail: jest.fn().mockReturnThis(),
          always: jest.fn().mockReturnThis(),
        }
      })
    })
    test('parse sets the id to the url', () => {
      const revision = new WikiPageRevision()
      expect(revision.parse({url: 'bob'}).id).toBe('bob')
    })

    test('toJSON omits the id', () => {
      const revision = new WikiPageRevision({url: 'url'})
      expect(revision.toJSON().id).toBeUndefined()
    })

    test('restore POSTs to the revision', async () => {
      const revision = new WikiPageRevision(
        {revision_id: 42},
        {
          contextAssetString: 'course_73',
          pageUrl: 'page-url',
        }
      )
      await revision.restore()
      expect($.ajaxJSON).toHaveBeenCalledWith(
        '/api/v1/courses/73/pages/page-url/revisions/42',
        'POST'
      )
    })
  })

  describe('fetch', () => {
    test('the summary flag is passed to the server', () => {
      jest.spyOn($, 'ajax').mockReturnValue($.Deferred())
      const revision = new WikiPageRevision(
        {},
        {
          contextAssetString: 'course_73',
          pageUrl: 'page-url',
          summary: true,
        }
      )
      revision.fetch()
      expect($.ajax.mock.calls[0][0].data.summary).toBe(true)
    })

    test('pollForChanges performs a fetch at most every interval', () => {
      const revision = new WikiPageRevision({}, {pageUrl: 'page-url'})
      jest.useFakeTimers()
      jest.spyOn(revision, 'fetch').mockReturnValue($.Deferred())
      revision.pollForChanges(5000)
      revision.pollForChanges(5000)
      jest.advanceTimersByTime(4000)
      expect(revision.fetch).not.toHaveBeenCalled()
      jest.advanceTimersByTime(2000)
      expect(revision.fetch).toHaveBeenCalledTimes(1)
      jest.useRealTimers()
    })
  })
})
