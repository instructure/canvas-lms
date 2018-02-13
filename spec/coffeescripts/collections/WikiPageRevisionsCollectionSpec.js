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

import WikiPage from 'compiled/models/WikiPage'
import WikiPageRevisionsCollection from 'compiled/collections/WikiPageRevisionsCollection'

QUnit.module('WikiPageRevisionsCollection')

test('parentModel accepted in constructor', () => {
  const parentModel = new WikiPage()
  const collection = new WikiPageRevisionsCollection([], {parentModel})
  strictEqual(collection.parentModel, parentModel, 'parentModel accepted in constructor')
})

test('url based on parentModel', () => {
  const parentModel = new WikiPage({url: 'a-page'}, {contextAssetString: 'course_73'})
  const collection = new WikiPageRevisionsCollection([], {parentModel})
  equal(collection.url(), '/api/v1/courses/73/pages/a-page/revisions', 'url built properly')
})

test('child models inherit parent url propertly', () => {
  const parentModel = new WikiPage({url: 'a-page'}, {contextAssetString: 'course_73'})
  const collection = new WikiPageRevisionsCollection([], {parentModel})
  collection.add({revision_id: 37})
  equal(collection.models.length, 1, 'child model added')
  equal(
    collection.models[0].url(),
    '/api/v1/courses/73/pages/a-page/revisions/37',
    'child url built properly'
  )
})
