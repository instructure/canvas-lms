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
import WikiPageRevision from 'compiled/models/WikiPageRevision'
import WikiPageRevisionsCollection from 'compiled/collections/WikiPageRevisionsCollection'
import WikiPageRevisionView from 'compiled/views/wiki/WikiPageRevisionView'

QUnit.module('WikiPageRevisionView')

test('binds to model change triggers', function() {
  const revision = new WikiPageRevision()
  const view = new WikiPageRevisionView({model: revision})
  this.mock(view)
    .expects('render')
    .atLeast(1)
  revision.set('body', 'A New Body')
})

test('restore delegates to model.restore', function() {
  const revision = new WikiPageRevision()
  const view = new WikiPageRevisionView({model: revision})
  this.stub(view, 'windowLocation').returns({
    href: '',
    reload() {
      return true
    }
  })
  this.mock(revision)
    .expects('restore')
    .atLeast(1)
    .returns($.Deferred().resolve())
  view.restore()
})

test('toJSON serializes expected values', () => {
  const attributes = {
    latest: true,
    selected: true,
    title: 'Title',
    body: 'Body'
  }
  const revision = new WikiPageRevision(attributes)
  const collection = new WikiPageRevisionsCollection([revision])
  collection.latest = new WikiPageRevision(attributes)
  const view = new WikiPageRevisionView({model: revision})
  const json = view.toJSON()
  strictEqual(json.IS != null ? json.IS.LATEST : undefined, true, 'IS.LATEST')
  strictEqual(json.IS != null ? json.IS.SELECTED : undefined, true, 'IS.SELECTED')
  strictEqual(json.IS != null ? json.IS.LOADED : undefined, true, 'IS.LOADED')
  strictEqual(json.IS != null ? json.IS.SAME_AS_LATEST : undefined, true, 'IS.SAME_AS_LATEST')
})
