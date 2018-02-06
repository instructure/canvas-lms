#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'jquery'
  'Backbone'
  'compiled/views/content_migrations/subviews/ExternalToolLaunchView'
  'helpers/assertions'
], ($, Backbone, ExternalToolLaunchView, assertions) ->

  QUnit.module 'ExternalToolLaunchView',
    setup: ->
      @mockMigration = new Backbone.Model
      @mockReturnView = new Backbone.View

      @launchView = new ExternalToolLaunchView
        contentReturnView: @mockReturnView
        model: @mockMigration

      $('#fixtures').html @launchView.render().el

    teardown: ->
      @launchView.remove()

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @launchView, done, {'a11yReport': true}

  test 'calls render on return view when launch button clicked', ->
    @stub(@mockReturnView, 'render').returns(this)
    @launchView.$el.find('#externalToolLaunch').click()
    ok @mockReturnView.render.calledOnce, 'render not called on return view'

  test "displays file name on 'ready'", ->
    @mockReturnView.trigger('ready', {contentItems: [{text: 'data text', url: 'data url'}]})
    strictEqual @launchView.$fileName.text(), 'data text'

  test "sets settings.data_url on migration on 'ready'", ->
    @mockReturnView.trigger('ready', {contentItems: [{text: 'data text', url: 'data url'}]})
    deepEqual @mockMigration.get('settings'), {file_url: 'data url'}
