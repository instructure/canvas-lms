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

import WikiPage from '../WikiPage'
import _ from 'lodash'

const ok = x => expect(x).toBeTruthy()
const equal = (a, b) => expect(a).toEqual(b)
const notEqual = (a, b) => expect(a).not.toEqual(b)
const strictEqual = (a, b) => expect(a).toEqual(b)

const wikiPageObj = function (options = {}) {
  return {
    body: '<p>content for the uploading of content</p>',
    created_at: '2013-05-10T13:18:27-06:00',
    editing_roles: 'teachers',
    front_page: false,
    hide_from_students: false,
    locked_for_user: false,
    published: false,
    title: 'Front Page-3',
    updated_at: '2013-06-13T10:30:37-06:00',
    url: 'front-page-2',
    ...options,
  }
}

describe('WikiPage', () => {
  test('latestRevision is only available when a url is provided', () => {
    let wikiPage = new WikiPage()
    equal(wikiPage.latestRevision(), undefined, 'not provided without url')
    wikiPage = new WikiPage({url: 'url'})
    notEqual(wikiPage.latestRevision(), null, 'provided with url')
  })

  test('revision passed to latestRevision', () => {
    const wikiPage = new WikiPage({url: 'url'}, {revision: 42})
    equal(wikiPage.latestRevision().get('revision_id'), 42, 'revision passed to latestRevision')
  })

  test('wiki page passed to latestRevision', () => {
    const wikiPage = new WikiPage({url: 'url'})
    equal(wikiPage.latestRevision().page, wikiPage, 'wiki page passed to latestRevision')
  })

  test('latestRevision should be marked as latest', () => {
    const wikiPage = new WikiPage({url: 'url'})
    equal(wikiPage.latestRevision().latest, true, 'marked as latest')
  })

  test('latestRevision should default to summary', () => {
    const wikiPage = new WikiPage({url: 'url'})
    equal(wikiPage.latestRevision().summary, true, 'defaulted to summary')
  })

  describe('WikiPage:Publishable', () => {
    test('publishable', () => {
      const wikiPage = new WikiPage({
        front_page: false,
        published: true,
      })
      strictEqual(wikiPage.get('publishable'), true, 'publishable set during construction')
      wikiPage.set('front_page', true)
      strictEqual(wikiPage.get('publishable'), false, 'publishable set when front_page changed')
    })

    test('deletable', () => {
      const wikiPage = new WikiPage({
        front_page: false,
        published: true,
      })
      strictEqual(wikiPage.get('deletable'), true, 'deletable set during construction')
      wikiPage.set('front_page', true)
      strictEqual(wikiPage.get('deletable'), false, 'deletable set when front_page changed')
    })
  })

  describe('WikiPage:Sync', () => {
    test('parse removes wiki_page namespace added by api', () => {
      const wikiPage = new WikiPage()
      const namespacedObj = {}
      namespacedObj.wiki_page = wikiPageObj()
      const parseResponse = wikiPage.parse(namespacedObj)
      ok(!_.isObject(parseResponse.wiki_page), 'Removes the wiki_page namespace')
    })

    test('present includes the context information', () => {
      const wikiPage = new WikiPage({}, {contextAssetString: 'course_31'})
      const json = wikiPage.present()
      equal(json.contextName, 'courses', 'contextName')
      equal(json.contextId, '31', 'contextId')
    })

    test('publish convenience method', () => {
      const wikiPage = new WikiPage(wikiPageObj())
      wikiPage.save = jest.fn(attributes => {
        ok(attributes, 'attributes present')
        ok(attributes.wiki_page, 'wiki_page present')
        strictEqual(attributes.wiki_page.published, true, 'published provided correctly')
      })
      wikiPage.publish()
      expect(wikiPage.save).toHaveBeenCalled()
    })

    test('unpublish convenience method', () => {
      const wikiPage = new WikiPage(wikiPageObj())
      wikiPage.save = jest.fn(attributes => {
        ok(attributes, 'attributes present')
        ok(attributes.wiki_page, 'wiki_page present')
        strictEqual(attributes.wiki_page.published, false, 'published provided correctly')
      })
      wikiPage.unpublish()
      expect(wikiPage.save).toHaveBeenCalled()
    })

    test('setFrontPage convenience method', () => {
      const wikiPage = new WikiPage(wikiPageObj())
      wikiPage.save = jest.fn(attributes => {
        ok(attributes, 'attributes present')
        ok(attributes.wiki_page, 'wiki_page present')
        strictEqual(attributes.wiki_page.front_page, true, 'front_page provided correctly')
      })
      wikiPage.setFrontPage()
      expect(wikiPage.save).toHaveBeenCalled()
    })

    test('unsetFrontPage convenience method', () => {
      const wikiPage = new WikiPage(wikiPageObj())
      wikiPage.save = jest.fn(attributes => {
        ok(attributes, 'attributes present')
        ok(attributes.wiki_page, 'wiki_page present')
        strictEqual(attributes.wiki_page.front_page, false, 'front_page provided correctly')
      })
      wikiPage.unsetFrontPage()
      expect(wikiPage.save).toHaveBeenCalled()
    })
  })
})
