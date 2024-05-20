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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import 'jquery-migrate'
import AdminToolsView from 'ui/features/account_admin_tools/backbone/views/AdminToolsView'
import assertions from 'helpers/assertions'

QUnit.module('AdminToolsViewSpec', {
  setup() {
    this.admin_tools_view = new AdminToolsView({
      restoreContentPaneView: new Backbone.View(),
      messageContentPaneView: new Backbone.View(),
      tabs: {
        courseRestore: true,
        viewMessages: true,
      },
    })
    return $('#fixtures').append(this.admin_tools_view.render().el)
  },
  teardown() {
    return this.admin_tools_view.remove()
  },
})

test('should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(
    this.admin_tools_view,
    function () {
      done()
    },
    {a11yReport: true}
  )
})

test('creates a new jquery tabs', function () {
  ok(this.admin_tools_view.$adminToolsTabs.data('ui-tabs'), 'There should be 2 tabs initialized')
})
