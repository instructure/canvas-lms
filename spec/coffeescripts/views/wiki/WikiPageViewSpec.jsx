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
import WikiPageView from 'ui/features/wiki_page_show/backbone/views/WikiPageView'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.simulate'
import '@canvas/module-sequence-footer'
import fakeENV from 'helpers/fakeENV'

QUnit.module('WikiPageView', hooks => {
  hooks.beforeEach(() => {
    fakeENV.setup()
  })

  hooks.afterEach(() => {
    fakeENV.teardown()
  })

  test('display_show_all_pages makes it through constructor', () => {
    const model = new WikiPage()
    const view = new WikiPageView({
      model,
      display_show_all_pages: true,
    })
    equal(view.display_show_all_pages, true)
  })

  test('model.view maintained by item view', () => {
    const model = new WikiPage()
    const view = new WikiPageView({model})
    strictEqual(model.view, view, 'model.view is set to the item view')
    view.render()
    strictEqual(model.view, view, 'model.view is set to the item view')
  })

  test('detach/reattach the publish icon view', () => {
    const model = new WikiPage()
    const view = new WikiPageView({model})
    view.render()
    const $previousEl = view.$el.find('> *:first-child')
    view.publishButtonView.$el.data('test-data', 'test-is-good')
    view.render()
    equal($previousEl.parent().length, 0, 'previous content removed')
    equal(
      view.publishButtonView.$el.data('test-data'),
      'test-is-good',
      'test data preserved (by detach)'
    )
  })

  QUnit.module('WikiPageView:JSON', _hooks => {
    test('modules_path', () => {
      const model = new WikiPage()
      const view = new WikiPageView({
        model,
        modules_path: '/courses/73/modules',
      })
      strictEqual(
        view.toJSON().modules_path,
        '/courses/73/modules',
        'modules_path represented in toJSON'
      )
    })

    test('wiki_pages_path', () => {
      const model = new WikiPage()
      const view = new WikiPageView({
        model,
        wiki_pages_path: '/groups/73/pages',
      })
      strictEqual(
        view.toJSON().wiki_pages_path,
        '/groups/73/pages',
        'wiki_pages_path represented in toJSON'
      )
    })

    test('wiki_page_edit_path', () => {
      const model = new WikiPage()
      const view = new WikiPageView({
        model,
        wiki_page_edit_path: '/groups/73/pages/37',
      })
      strictEqual(
        view.toJSON().wiki_page_edit_path,
        '/groups/73/pages/37',
        'wiki_page_edit_path represented in toJSON'
      )
    })

    test('wiki_page_history_path', () => {
      const model = new WikiPage()
      const view = new WikiPageView({
        model,
        wiki_page_edit_path: '/groups/73/pages/37/revisions',
      })
      strictEqual(
        view.toJSON().wiki_page_edit_path,
        '/groups/73/pages/37/revisions',
        'wiki_page_history_path represented in toJSON'
      )
    })

    test('lock_info.unlock_at', () => {
      const clock = sinon.useFakeTimers(new Date(2012, 0, 31).getTime())
      const model = new WikiPage({
        locked_for_user: true,
        lock_info: {unlock_at: '2012-02-15T12:00:00Z'},
      })
      const view = new WikiPageView({model})
      const lockInfo = view.toJSON().lock_info
      ok(
        !!(lockInfo && lockInfo.unlock_at.match('Feb')),
        'lock_info.unlock_at reformatted and represented in toJSON'
      )
      clock.restore()
    })

    test('useAsFrontPage for published wiki_pages_path', () => {
      const model = new WikiPage({
        front_page: false,
        published: true,
      })
      const view = new WikiPageView({model})
      const stub = sandbox.stub(model, 'setFrontPage')
      view.useAsFrontPage()
      ok(stub.calledOnce)
    })

    test('useAsFrontPage should not work on unpublished wiki_pages_path', () => {
      const model = new WikiPage({
        front_page: false,
        published: false,
      })
      const view = new WikiPageView({model})
      const stub = sandbox.stub(model, 'setFrontPage')
      view.useAsFrontPage()
      notOk(stub.calledOnce)
    })
  })

  QUnit.module('WikiPageView: direct share', hooks2 => {
    hooks2.beforeEach(() => {
      $('<div id="direct-share-mount-point">').appendTo('#fixtures')
      fakeENV.setup({DIRECT_SHARE_ENABLED: true})
      sinon.stub(ReactDOM, 'render')
    })

    hooks2.afterEach(() => {
      ReactDOM.render.restore()
      fakeENV.teardown()
      $('#direct-share-mount-point').remove()
    })

    test('opens and closes user share modal', () => {
      const model = new WikiPage({
        page_id: '42',
        url: 'foo',
      })
      const view = new WikiPageView({model, course_id: '123', PAGE_RIGHTS: {update_content: true}})
      view.render()
      view.$('.al-trigger').simulate('click')
      view.$('.direct-share-send-to-menu-item').simulate('click')
      const props = ReactDOM.render.firstCall.args[0].props
      equal(props.open, true)
      equal(props.sourceCourseId, '123')
      deepEqual(props.contentShare, {content_type: 'page', content_id: '42'})
      props.onDismiss()
      equal(ReactDOM.render.lastCall.args[0].props.open, false)
    })

    test('opens and closes copy to tray', () => {
      const model = new WikiPage({
        page_id: '42',
        url: 'foo',
      })
      const view = new WikiPageView({model, course_id: '123', PAGE_RIGHTS: {update_content: true}})
      view.render()
      view.$('.al-trigger').simulate('click')
      view.$('.direct-share-copy-to-menu-item').simulate('click')
      const props = ReactDOM.render.firstCall.args[0].props
      equal(props.open, true)
      equal(props.sourceCourseId, '123')
      deepEqual(props.contentSelection, {pages: ['42']})
      props.onDismiss()
      equal(ReactDOM.render.lastCall.args[0].props.open, false)
    })
  })
})

const testRights = (subject, options) => {
  test(`${subject}`, () => {
    const model = new WikiPage(options.attributes, {contextAssetString: options.contextAssetString})
    const view = new WikiPageView({
      model,
      WIKI_RIGHTS: options.WIKI_RIGHTS,
      PAGE_RIGHTS: options.PAGE_RIGHTS,
      course_home: options.course_home,
    })
    const json = view.toJSON()
    for (const key in options.CAN) {
      strictEqual(json.CAN[key], options.CAN[key], `${subject} - CAN.${key}`)
    }
  })
}

testRights('CAN (manage)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {
    read: true,
    publish_page: true,
    manage: true,
  },
  PAGE_RIGHTS: {
    update: true,
    delete: true,
    read_revisions: true,
  },
  CAN: {
    VIEW_PAGES: true,
    PUBLISH: true,
    VIEW_UNPUBLISHED: true,
    UPDATE_CONTENT: true,
    DELETE: true,
    READ_REVISIONS: true,
    ACCESS_GEAR_MENU: true,
  },
})

testRights('CAN (update)', {
  contextAssetString: 'group_73',
  WIKI_RIGHTS: {
    read: true,
    manage: true,
  },
  PAGE_RIGHTS: {
    update_content: true,
    read_revisions: true,
  },
  CAN: {
    VIEW_PAGES: true,
    PUBLISH: false,
    VIEW_UNPUBLISHED: true,
    UPDATE_CONTENT: true,
    DELETE: false,
    READ_REVISIONS: true,
    ACCESS_GEAR_MENU: true,
  },
})

testRights('CAN (read)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {read: true},
  PAGE_RIGHTS: {read: true},
  CAN: {
    VIEW_PAGES: true,
    PUBLISH: false,
    VIEW_UNPUBLISHED: false,
    UPDATE_CONTENT: false,
    DELETE: false,
    READ_REVISIONS: false,
    ACCESS_GEAR_MENU: false,
  },
})

testRights('CAN (null)', {
  CAN: {
    VIEW_PAGES: false,
    PUBLISH: false,
    VIEW_UNPUBLISHED: false,
    UPDATE_CONTENT: false,
    DELETE: false,
    READ_REVISIONS: false,
    ACCESS_GEAR_MENU: false,
  },
})

testRights('CAN (manage, course home page)', {
  contextAssetString: 'course_73',
  course_home: true,
  WIKI_RIGHTS: {
    read: true,
    publish_page: true,
    manage: true,
  },
  PAGE_RIGHTS: {
    update: true,
    delete: true,
    read_revisions: true,
  },
  CAN: {
    VIEW_PAGES: true,
    PUBLISH: true,
    VIEW_UNPUBLISHED: true,
    UPDATE_CONTENT: true,
    DELETE: false,
    READ_REVISIONS: true,
    ACCESS_GEAR_MENU: true,
  },
})

testRights('CAN (view toolbar on course_home)', {
  course_home: true,
  display_show_all_pages: false,
  WIKI_RIGHTS: {
    manage: false,
  },
  CAN: {
    VIEW_TOOLBAR: true,
  },
})
