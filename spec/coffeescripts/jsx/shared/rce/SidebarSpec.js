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

import Sidebar from '@canvas/rce/Sidebar'
import RCELoader from '@canvas/rce/serviceRCELoader'
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

test('loads remote sidebar when feature flag on', () => {
  const remoteSidebar = {is_a: 'remote_sidebar'}
  sandbox.stub(RCELoader, 'loadSidebarOnTarget').callsArgWith(1, remoteSidebar)
  Sidebar.pendingShow = false
  Sidebar.init()
  equal(Sidebar.instance, remoteSidebar)
})
