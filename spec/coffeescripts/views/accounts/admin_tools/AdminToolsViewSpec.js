#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'jquery'
  'compiled/views/accounts/admin_tools/AdminToolsView'
  'helpers/assertions'
], (Backbone, $, AdminToolsView, assertions) ->
  QUnit.module 'AdminToolsViewSpec',
    setup: ->
      @admin_tools_view = new AdminToolsView
        restoreContentPaneView: new Backbone.View
        messageContentPaneView: new Backbone.View
        tabs:
          courseRestore: true
          viewMessages: true

      $('#fixtures').append @admin_tools_view.render().el

    teardown: ->
      @admin_tools_view.remove()

  test 'should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @admin_tools_view, done, {'a11yReport': true}

  test "creates a new jquery tabs", ->
    ok @admin_tools_view.$adminToolsTabs.data('tabs'), "There should be 2 tabs initialized"
