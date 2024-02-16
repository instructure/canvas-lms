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
import WikiPageCollection from 'ui/features/wiki_page_index/backbone/collections/WikiPageCollection'
import WikiPageIndexView from 'ui/features/wiki_page_index/backbone/views/WikiPageIndexView'
import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.disableWhileLoading'
import fakeENV from 'helpers/fakeENV'
import {ltiState} from '@canvas/lti/jquery/messages'
import * as ConfirmDeleteModal from 'ui/features/wiki_page_index/react/ConfirmDeleteModal'

const indexMenuLtiTool = {
  id: '18',
  title: 'Named LTI Tool',
  base_url: 'http://localhost/courses/1/external_tools/18?launch_type=wiki_index_menu',
  tool_id: 'named_lti_tool',
  icon_url: 'http://localhost:3001/icon.png',
  canvas_icon_class: null,
}

let prevHtml

QUnit.module('WikiPageIndexView:confirmDeletePages not checked', {
  setup() {
    prevHtml = document.body.innerHTML
    fakeENV.setup()
    this.model = new WikiPage({page_id: '42'})
    this.collection = new WikiPageCollection([this.model])
    this.view = new WikiPageIndexView({
      collection: this.collection,
    })
  },

  teardown() {
    document.body.innerHTML = prevHtml
    fakeENV.teardown()
  },
})

test('does not call showConfirmDelete when no pages are checked', function () {
  const showConfirmDelete = sandbox.spy(ConfirmDeleteModal, 'showConfirmDelete')
  this.view.confirmDeletePages(null)
  notOk(showConfirmDelete.called)
})

QUnit.module('WikiPageIndexView:confirmDeletePages checked', {
  setup() {
    prevHtml = document.body.innerHTML
    fakeENV.setup()
    this.model = new WikiPage({page_id: '42', title: 'page 42'})
    this.collection = new WikiPageCollection([this.model])
    this.view = new WikiPageIndexView({
      collection: this.collection,
      selectedPages: {42: this.model},
    })
  },

  teardown() {
    document.body.innerHTML = prevHtml
    fakeENV.teardown()
  },
})
test('calls showConfirmDelete when pages are checked', function () {
  const showConfirmDelete = sandbox.spy(ConfirmDeleteModal, 'showConfirmDelete')
  this.view.confirmDeletePages(null)
  ok(
    showConfirmDelete.firstCall.calledWithMatch({
      pageTitles: ['page 42'],
    })
  )
})

QUnit.module('WikiPageIndexView:direct_share', {
  setup() {
    fakeENV.setup()
    ENV.DIRECT_SHARE_ENABLED = true
    ENV.COURSE_ID = 'a course'
    this.model = new WikiPage({page_id: '42'})
    this.collection = new WikiPageCollection([this.model])
    this.view = new WikiPageIndexView({
      collection: this.collection,
      WIKI_RIGHTS: {
        create_page: true,
        manage: true,
      },
    })
  },

  teardown() {
    fakeENV.teardown()
  },
})

test('opens and closes the direct share course tray', function () {
  const trayComponent = sandbox.stub(this.view, 'DirectShareCourseTray').returns(null)
  this.collection.trigger('fetch')
  this.view.$el.find('.copy-wiki-page-to').click()
  ok(
    trayComponent.firstCall.calledWithMatch({
      open: true,
      sourceCourseId: 'a course',
      contentSelection: {pages: ['42']},
    })
  )
  trayComponent.firstCall.args[0].onDismiss()
  ok(trayComponent.secondCall.calledWithMatch({open: false}))
})

test('opens and closes the direct share user modal', function () {
  const userModal = sandbox.stub(this.view, 'DirectShareUserModal').returns(null)
  this.collection.trigger('fetch')
  this.view.$el.find('.send-wiki-page-to').click()
  ok(
    userModal.firstCall.calledWithMatch({
      open: true,
      courseId: 'a course',
      contentShare: {
        content_id: '42',
        content_type: 'page',
      },
    })
  )
  userModal.firstCall.args[0].onDismiss()
  ok(userModal.secondCall.calledWithMatch({open: false}))
})

QUnit.module('WikiPageIndexView:open_external_tool', {
  setup() {
    fakeENV.setup()
    ENV.COURSE_ID = 'a course'
    this.model = new WikiPage({page_id: '42'})
    this.collection = new WikiPageCollection([this.model])
    this.view = new WikiPageIndexView({
      collection: this.collection,
      WIKI_RIGHTS: {
        create_page: true,
        manage: true,
      },
      wikiIndexPlacements: indexMenuLtiTool,
    })
  },

  teardown() {
    fakeENV.teardown()
    delete window.ltiTrayState
  },
})

test('opens and closes the lti tray and returns focus', function () {
  const trayComponent = sandbox.stub(this.view, 'ContentTypeExternalToolTray').returns(null)
  this.collection.trigger('fetch')
  const toolbarKabobMenu = this.view.$el.find('.al-trigger')[0]
  this.view.setExternalToolTray(indexMenuLtiTool, toolbarKabobMenu)
  ok(
    trayComponent.firstCall.calledWithMatch({
      tool: indexMenuLtiTool,
      placement: 'wiki_index_menu',
      acceptedResourceTypes: ['page'],
      targetResourceType: 'page',
      allowItemSelection: false,
      selectableItems: [],
      open: true,
    })
  )
  trayComponent.firstCall.args[0].onDismiss()
  ok(trayComponent.secondCall.calledWithMatch({open: false}))
})

test('reloads page when closing tray if needed', function () {
  const trayComponent = sandbox.stub(this.view, 'ContentTypeExternalToolTray').returns(null)
  const pageReload = sandbox.stub(this.view, 'reloadPage').returns(null)
  this.collection.trigger('fetch')
  const toolbarKabobMenu = this.view.$el.find('.al-trigger')[0]
  this.view.setExternalToolTray(indexMenuLtiTool, toolbarKabobMenu)
  ok(
    trayComponent.firstCall.calledWithMatch({
      tool: indexMenuLtiTool,
      placement: 'wiki_index_menu',
      acceptedResourceTypes: ['page'],
      targetResourceType: 'page',
      allowItemSelection: false,
      selectableItems: [],
      open: true,
    })
  )
  ltiState.tray = {refreshOnClose: true}
  trayComponent.firstCall.args[0].onDismiss()
  ok(trayComponent.secondCall.calledWithMatch({open: false}))
  ok(pageReload.called)
})

QUnit.module('WikiPageIndexView:sort', {
  setup() {
    this.collection = new WikiPageCollection()
    this.view = new WikiPageIndexView({collection: this.collection})
    this.$a = $('<a/>')
    this.$a.data('sort-field', 'created_at')
    this.ev = $.Event('click')
    this.ev.currentTarget = this.$a.get(0)
  },
})

test('sort delegates to the collection sortByField', function () {
  const sortByFieldStub = sandbox.stub(this.collection, 'sortByField')
  this.view.sort(this.ev)
  ok(sortByFieldStub.calledOnce, 'collection sortByField called once')
})

test('view disabled while sorting', function () {
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

test('view disabled while sorting again', function () {
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

test('renderSortHeaders called when sorting changes', function () {
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
      WIKI_RIGHTS: options.WIKI_RIGHTS,
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
    publish_page: true,
    update: true,
    manage: true,
  },
  CAN: {
    CREATE: true,
    MANAGE: true,
    PUBLISH: true,
  },
})

testRights('CAN (manage group)', {
  contextAssetString: 'group_73',
  WIKI_RIGHTS: {
    read: true,
    create_page: true,
    update: true,
    manage: true,
  },
  CAN: {
    CREATE: true,
    MANAGE: true,
    PUBLISH: false,
  },
})

testRights('CAN (read)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {read: true},
  CAN: {
    CREATE: false,
    MANAGE: false,
    PUBLISH: false,
  },
})

testRights('CAN (null)', {
  CAN: {
    CREATE: false,
    MANAGE: false,
    PUBLISH: false,
  },
})

// Granular permissions tests

testRights('CAN (read)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {update: true},
  CAN: {
    CREATE: false,
    MANAGE: true,
    PUBLISH: false,
  },
})

testRights('CAN (read)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {delete_page: true},
  CAN: {
    CREATE: false,
    MANAGE: true,
    PUBLISH: false,
  },
})

testRights('CAN (view toolbar)', {
  contextAssetString: 'course_73',
  WIKI_RIGHTS: {delete_page: true},
  CAN: {
    CREATE: false,
    MANAGE: true,
    PUBLISH: false,
    VIEW_TOOLBAR: true,
  },
})
