/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Sidebar from 'jsx/shared/rce/Sidebar'
import RCELoader from 'jsx/shared/rce/serviceRCELoader'
import wikiSidebar from 'wikiSidebar'
import fakeENV from 'helpers/fakeENV'
import editorUtils from 'helpers/editorUtils'

QUnit.module('Sidebar - init', {
  setup() {
    // in case other specs left it not fresh
    editorUtils.resetRCE()
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
    editorUtils.resetRCE()
  }
})

test('uses wikiSidebar when feature flag off', () => {
  ENV.RICH_CONTENT_SERVICE_ENABLED = false
  sinon.spy(wikiSidebar, 'init')
  Sidebar.init()
  equal(Sidebar.instance, wikiSidebar)
  ok(wikiSidebar.init.called)
  wikiSidebar.init.restore()
})

test('loads remote sidebar when feature flag on', function() {
  ENV.RICH_CONTENT_SERVICE_ENABLED = true
  const remoteSidebar = {is_a: 'remote_sidebar'}
  sandbox.stub(RCELoader, 'loadSidebarOnTarget').callsArgWith(1, remoteSidebar)
  Sidebar.pendingShow = false
  Sidebar.init()
  equal(Sidebar.instance, remoteSidebar)
})

test('repeated calls only init instance once', () => {
  ENV.RICH_CONTENT_SERVICE_ENABLED = false
  sinon.spy(wikiSidebar, 'init')
  Sidebar.init()
  Sidebar.init()
  Sidebar.init()
  ok(wikiSidebar.init.calledOnce)
  wikiSidebar.init.restore()
})

QUnit.module('Sidebar - show', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
  },
  teardown() {
    fakeENV.teardown()
    editorUtils.resetRCE()
  }
})

test('when not initialized does nothing', () => {
  sinon.spy(wikiSidebar, 'show')
  Sidebar.show()
  ok(wikiSidebar.show.notCalled)
  wikiSidebar.show.restore()
})

test('when initialized calls show on sidebar implementor', () => {
  sinon.spy(wikiSidebar, 'show')
  Sidebar.init()
  Sidebar.show()
  ok(wikiSidebar.show.called)
  wikiSidebar.show.restore()
})

test('when initialized with show callback calls callback', () => {
  const cb = sinon.spy()
  Sidebar.init({show: cb})
  Sidebar.show()
  ok(cb.called)
})

test('when repeatedly initialized only calls most recent callback', () => {
  const cb1 = sinon.spy()
  const cb2 = sinon.spy()
  Sidebar.init({show: cb1})
  Sidebar.init({show: cb2})
  Sidebar.show()
  ok(cb1.notCalled)
  ok(cb2.called)
})

QUnit.module('Sidebar - hide', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
  },
  teardown() {
    fakeENV.teardown()
    editorUtils.resetRCE()
  }
})

test('when not initialized does nothing', () => {
  sinon.spy(wikiSidebar, 'hide')
  Sidebar.hide()
  ok(wikiSidebar.hide.notCalled)
  wikiSidebar.hide.restore()
})

test('when initialized calls hide on sidebar implementor', () => {
  sinon.spy(wikiSidebar, 'hide')
  Sidebar.init()
  Sidebar.hide()
  ok(wikiSidebar.hide.called)
  wikiSidebar.hide.restore()
})

test('when initialized with hide callback calls callback after hide', () => {
  const cb = sinon.spy()
  Sidebar.init({hide: cb})
  Sidebar.hide()
  ok(cb.called)
})

test('when repeatedly initialized only calls most recent callback', () => {
  const cb1 = sinon.spy()
  const cb2 = sinon.spy()
  Sidebar.init({hide: cb1})
  Sidebar.init({hide: cb2})
  Sidebar.hide()
  ok(cb1.notCalled)
  ok(cb2.called)
})
