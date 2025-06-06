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

import WikiPage from '@canvas/wiki/backbone/models/WikiPage'
import WikiPageIndexItemView from '../WikiPageIndexItemView'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('WikiPageIndex', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })
  describe('WikiPageIndexItemView', () => {
    test('model.view maintained by item view', () => {
      const model = new WikiPage()
      const view = new WikiPageIndexItemView({
        model,
        collectionHasTodoDate: () => {},
        selectedPages: {},
      })
      expect(model.view).toBe(view)
      view.render()
      expect(model.view).toBe(view)
    })

    test('detach/reattach the publish icon view', () => {
      const model = new WikiPage()
      const view = new WikiPageIndexItemView({
        model,
        collectionHasTodoDate: () => {},
        selectedPages: {},
      })
      view.render()
      const $previousEl = view.$el.find('> *:first-child')
      view.publishIconView.$el.data('test-data', 'test-is-good')
      view.render()
      expect($previousEl.parent()).toHaveLength(0)
      expect(view.publishIconView.$el.data('test-data')).toBe('test-is-good')
    })

    test('delegate useAsFrontPage to the model', () => {
      const model = new WikiPage({
        front_page: false,
        published: true,
      })
      const view = new WikiPageIndexItemView({
        model,
        collectionHasTodoDate: () => {},
        selectedPages: {},
      })
      const stub = jest.spyOn(model, 'setFrontPage').mockImplementation()
      view.useAsFrontPage()
      expect(stub).toHaveBeenCalledTimes(1)
      stub.mockRestore()
    })

    test('only shows direct share menu items if enabled', () => {
      const view = new WikiPageIndexItemView({
        model: new WikiPage(),
        collectionHasTodoDate: () => {},
        selectedPages: {},
        WIKI_RIGHTS: {read: true, manage: true, update: true},
        CAN: {MANAGE: true},
      })
      view.render()
      expect(view.$('.send-wiki-page-to')).toHaveLength(0)
      expect(view.$('.copy-wiki-page-to')).toHaveLength(0)

      ENV.DIRECT_SHARE_ENABLED = true
      view.render()
      expect(view.$('.send-wiki-page-to').length).toBeGreaterThan(0)
      expect(view.$('.copy-wiki-page-to').length).toBeGreaterThan(0)
    })
  })

  describe('WikiPageIndexItemView:JSON', () => {
    const testRights = (subject, options) => {
      test(`${subject}`, () => {
        const model = new WikiPage()
        const view = new WikiPageIndexItemView({
          model,
          contextName: options.contextName,
          WIKI_RIGHTS: options.WIKI_RIGHTS,
          collectionHasTodoDate: () => {},
          selectedPages: {},
        })
        const json = view.toJSON()
        for (const key in options.CAN) {
          expect(json.CAN[key]).toBe(options.CAN[key])
        }
      })
    }

    testRights('CAN (manage course)', {
      contextName: 'courses',
      WIKI_RIGHTS: {
        read: true,
        manage: true,
        publish_page: true,
        create_page: true,
      },
      CAN: {
        MANAGE: true,
        PUBLISH: true,
        DUPLICATE: true,
      },
    })

    testRights('CAN (manage group)', {
      contextName: 'groups',
      WIKI_RIGHTS: {
        read: true,
        manage: true,
        publish_page: false,
        create_page: true,
      },
      CAN: {
        MANAGE: true,
        PUBLISH: false,
        DUPLICATE: false,
      },
    })

    testRights('CAN (read)', {
      contextName: 'courses',
      WIKI_RIGHTS: {read: true},
      CAN: {
        MANAGE: false,
        PUBLISH: false,
      },
    })

    testRights('CAN (null)', {
      CAN: {
        MANAGE: false,
        PUBLISH: false,
      },
    })

    // Tests for granular permissions, with manage permission removed
    testRights('CAN (create page - course)', {
      contextName: 'courses',
      WIKI_RIGHTS: {create_page: true},
      CAN: {
        MANAGE: true,
        PUBLISH: false,
        DUPLICATE: true,
        UPDATE: false,
        DELETE: false,
      },
    })

    testRights('CAN (create page - group)', {
      contextName: 'groups',
      WIKI_RIGHTS: {create_page: true},
      CAN: {
        MANAGE: true,
        PUBLISH: false,
        DUPLICATE: false,
        UPDATE: false,
        DELETE: false,
      },
    })

    testRights('CAN (delete page)', {
      contextName: 'courses',
      WIKI_RIGHTS: {delete_page: true},
      CAN: {
        MANAGE: true,
        PUBLISH: false,
        DUPLICATE: false,
        UPDATE: false,
        DELETE: true,
      },
    })

    testRights('CAN (update page)', {
      contextName: 'courses',
      WIKI_RIGHTS: {update: true, publish_page: true},
      CAN: {
        MANAGE: true,
        PUBLISH: true,
        DUPLICATE: false,
        UPDATE: true,
        DELETE: false,
      },
    })

    test('includes is_checked', () => {
      const model = new WikiPage({
        page_id: '42',
      })
      const view = new WikiPageIndexItemView({
        model,
        collectionHasTodoDate: () => {},
        selectedPages: {42: model},
      })
      expect(view.toJSON().isChecked).toBe(true)
    })
  })
})
