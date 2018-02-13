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

import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import globalAnnouncements from 'global_announcements'
import serviceRCELoader from 'jsx/shared/rce/serviceRCELoader'

QUnit.module('GlobalAnnouncements', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    this.loadOnTargetStub = sinon.stub(serviceRCELoader, 'loadOnTarget')
  },
  teardown() {
    serviceRCELoader.loadOnTarget.restore()
    $('#fixtures').empty()
    fakeENV.teardown()
  }
})

test('loads an editor for every matching node', function() {
  const html =
    "<textarea id='a1' class='edit_notification_form'>Announcement 1</textarea>" +
    "<textarea id='a2' class='edit_notification_form'>Announcement 2</textarea>" +
    "<form id='add_notification_form'><textarea id='a3'></textarea></form>"
  $(html).appendTo('#fixtures')
  globalAnnouncements.augmentView()
  ok(this.loadOnTargetStub.calledThrice)
})
