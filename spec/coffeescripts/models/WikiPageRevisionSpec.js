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
import WikiPage from '@canvas/wiki/backbone/models/WikiPage'
import WikiPageRevision from '@canvas/wiki/backbone/models/WikiPageRevision'
import '@canvas/jquery/jquery.ajaxJSON'

QUnit.module('WikiPageRevision::urls')

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
  strictEqual(revision.contextAssetString, 'course_73', 'contextAssetString')
  strictEqual(revision.page, page, 'page')
  strictEqual(revision.pageUrl, 'page-url', 'pageUrl')
  strictEqual(revision.latest, true, 'latest')
  strictEqual(revision.summary, true, 'summary')
})

test('urlRoot uses the context path and pageUrl', () => {
  const revision = new WikiPageRevision(
    {},
    {
      contextAssetString: 'course_73',
      pageUrl: 'page-url',
    }
  )
  strictEqual(revision.urlRoot(), '/api/v1/courses/73/pages/page-url/revisions', 'base url')
})

test('url returns urlRoot if latest and id are not specified', () => {
  const revision = new WikiPageRevision(
    {},
    {
      contextAssetString: 'course_73',
      pageUrl: 'page-url',
    }
  )
  strictEqual(revision.url(), '/api/v1/courses/73/pages/page-url/revisions', 'base url')
})

test('url is affected by the revision_id attribute', () => {
  const revision = new WikiPageRevision(
    {revision_id: 42},
    {
      contextAssetString: 'course_73',
      pageUrl: 'page-url',
    }
  )
  strictEqual(revision.url(), '/api/v1/courses/73/pages/page-url/revisions/42', 'revision 42')
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
  strictEqual(revision.url(), '/api/v1/courses/73/pages/page-url/revisions/latest', 'latest')
})

QUnit.module('WikiPageRevision::parse')

test('parse sets the id to the url', () => {
  const revision = new WikiPageRevision()
  strictEqual(revision.parse({url: 'bob'}).id, 'bob', 'url set through parse')
})

test('toJSON omits the id', () => {
  const revision = new WikiPageRevision({url: 'url'})
  strictEqual(revision.toJSON().id, undefined, 'id omitted')
})

test('restore POSTs to the revision', () => {
  const revision = new WikiPageRevision(
    {revision_id: 42},
    {
      contextAssetString: 'course_73',
      pageUrl: 'page-url',
    }
  )
  const mock = sandbox.mock($)
  mock
    .expects('ajaxJSON')
    .atLeast(1)
    .withArgs('/api/v1/courses/73/pages/page-url/revisions/42', 'POST')
    .returns($.Deferred().resolve())
  return revision.restore()
})

QUnit.module('WikiPageRevision::fetch')

test('the summary flag is passed to the server', () => {
  sandbox.stub($, 'ajax').returns($.Deferred())
  const revision = new WikiPageRevision(
    {},
    {
      contextAssetString: 'course_73',
      pageUrl: 'page-url',
      summary: true,
    }
  )
  revision.fetch()
  strictEqual($.ajax.args[0][0].data.summary, true, 'summary provided')
})

test('pollForChanges performs a fetch at most every interval', () => {
  const revision = new WikiPageRevision({}, {pageUrl: 'page-url'})
  const clock = sinon.useFakeTimers()
  sandbox.stub(revision, 'fetch').returns($.Deferred())
  revision.pollForChanges(5000)
  revision.pollForChanges(5000)
  clock.tick(4000)
  ok(!revision.fetch.called, 'not called until interval elapses')
  clock.tick(2000)
  ok(revision.fetch.calledOnce, 'called once interval elapses')
  return clock.restore()
})
