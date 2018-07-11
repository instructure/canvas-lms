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

import WikiPageCollection from 'compiled/collections/WikiPageCollection'
import WikiPageIndexView from 'compiled/views/wiki/WikiPageIndexView'
import $ from 'jquery'
import 'jquery.disableWhileLoading'

QUnit.module('WikiPageIndexView:sort', {
  setup() {
    this.collection = new WikiPageCollection()
    this.view = new WikiPageIndexView({collection: this.collection})
    this.$a = $('<a/>')
    this.$a.data('sort-field', 'created_at')
    this.ev = $.Event('click')
    this.ev.currentTarget = this.$a.get(0)
  }
})

test('sort delegates to the collection sortByField', function() {
  const sortByFieldStub = sandbox.stub(this.collection, 'sortByField')
  this.view.sort(this.ev)
  ok(sortByFieldStub.calledOnce, 'collection sortByField called once')
})

test('view disabled while sorting', function() {
  const dfd = $.Deferred()
  sandbox.stub(this.collection, 'fetch').returns(dfd)
  const disableWhileLoadingStub = sandbox.stub(this.view.$el, 'disableWhileLoading')
  this.view.sort(this.ev)
  ok(disableWhileLoadingStub.calledOnce, 'disableWhileLoading called once')
  ok(
    disableWhileLoadingStub.calledWith(dfd),
    'disableWhileLoading called with correct deferred object'
  )
})

test('view disabled while sorting again', function() {
  const dfd = $.Deferred()
  sandbox.stub(this.collection, 'fetch').returns(dfd)
  const disableWhileLoadingStub = sandbox.stub(this.view.$el, 'disableWhileLoading')
  this.view.sort(this.ev)
  ok(disableWhileLoadingStub.calledOnce, 'disableWhileLoading called once')
  ok(
    disableWhileLoadingStub.calledWith(dfd),
    'disableWhileLoading called with correct deferred object'
  )
})

test('renderSortHeaders called when sorting changes', function() {
  const renderSortHeadersStub = sandbox.stub(this.view, 'renderSortHeaders')
  this.collection.trigger('sortChanged', 'created_at')
  ok(renderSortHeadersStub.calledOnce, 'renderSortHeaders called once')
  equal(this.view.currentSortField, 'created_at', 'currentSortField set correctly')
})

QUnit.module('WikiPageIndexView:JSON')

const testRights = (subject, options) =>
  test(`${subject}`, () => {
    const collection = new WikiPageCollection()
    const view = new WikiPageIndexView({
      collection,
      contextAssetString: options.contextAssetString,
      WIKI_RIGHTS: options.WIKI_RIGHTS
    })
    const json = view.toJSON()
    for (const key in options.CAN) {
      strictEqual(json.CAN[key], options.CAN[key], `CAN.${key}`)
    }
  })

testRights('CAN (manage course)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {
    read: true,
    create_page: true,
    manage: true
  },
  CAN: {
    CREATE: true,
    MANAGE: true,
    PUBLISH: true
  }
})

testRights('CAN (manage group)', {
  contextAssetString: 'group_73',
  WIKI_RIGHTS: {
    read: true,
    create_page: true,
    manage: true
  },
  CAN: {
    CREATE: true,
    MANAGE: true,
    PUBLISH: false
  }
})

testRights('CAN (read)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {read: true},
  CAN: {
    CREATE: false,
    MANAGE: false,
    PUBLISH: false
  }
})

testRights('CAN (null)', {
  CAN: {
    CREATE: false,
    MANAGE: false,
    PUBLISH: false
  }
})
