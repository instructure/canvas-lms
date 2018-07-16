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
import WikiPageIndexItemView from 'compiled/views/wiki/WikiPageIndexItemView'

QUnit.module('WikiPageIndexItemView')

test('model.view maintained by item view', () => {
  const model = new WikiPage()
  const view = new WikiPageIndexItemView({model, collectionHasTodoDate: () => {}})
  strictEqual(model.view, view, 'model.view is set to the item view')
  view.render()
  strictEqual(model.view, view, 'model.view is set to the item view')
})

test('detach/reattach the publish icon view', () => {
  const model = new WikiPage()
  const view = new WikiPageIndexItemView({model, collectionHasTodoDate: () => {}})
  view.render()
  const $previousEl = view.$el.find('> *:first-child')
  view.publishIconView.$el.data('test-data', 'test-is-good')
  view.render()
  equal($previousEl.parent().length, 0, 'previous content removed')
  equal(
    view.publishIconView.$el.data('test-data'),
    'test-is-good',
    'test data preserved (by detach)'
  )
})

test('delegate useAsFrontPage to the model', function() {
  const model = new WikiPage({
    front_page: false,
    published: true
  })
  const view = new WikiPageIndexItemView({model, collectionHasTodoDate: () => {}})
  const stub = sandbox.stub(model, 'setFrontPage')
  view.useAsFrontPage()
  ok(stub.calledOnce)
})

QUnit.module('WikiPageIndexItemView:JSON')

const testRights = (subject, options) =>
  test(`${subject}`, () => {
    const model = new WikiPage()
    const view = new WikiPageIndexItemView({
      model,
      contextName: options.contextName,
      WIKI_RIGHTS: options.WIKI_RIGHTS,
      collectionHasTodoDate: () => {}
    })
    const json = view.toJSON()
    for (const key in options.CAN) {
      strictEqual(json.CAN[key], options.CAN[key], `CAN.${key}`)
    }
  })

testRights('CAN (manage course)', {
  contextName: 'courses',
  WIKI_RIGHTS: {
    read: true,
    manage: true
  },
  CAN: {
    MANAGE: true,
    PUBLISH: true,
    DUPLICATE: true
  }
})

testRights('CAN (manage group)', {
  contextName: 'groups',
  WIKI_RIGHTS: {
    read: true,
    manage: true
  },
  CAN: {
    MANAGE: true,
    PUBLISH: false,
    DUPLICATE: false
  }
})

testRights('CAN (read)', {
  contextName: 'courses',
  WIKI_RIGHTS: {read: true},
  CAN: {
    MANAGE: false,
    PUBLISH: false
  }
})

testRights('CAN (null)', {
  CAN: {
    MANAGE: false,
    PUBLISH: false
  }
})
