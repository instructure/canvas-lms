/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import Backbone from 'Backbone'
import ExternalToolLaunchView from 'compiled/views/content_migrations/subviews/ExternalToolLaunchView'
import assertions from 'helpers/assertions'

QUnit.module('ExternalToolLaunchView', {
  setup() {
    this.mockMigration = new Backbone.Model()
    this.mockReturnView = new Backbone.View()
    this.launchView = new ExternalToolLaunchView({
      contentReturnView: this.mockReturnView,
      model: this.mockMigration
    })
    return $('#fixtures').html(this.launchView.render().el)
  },
  teardown() {
    return this.launchView.remove()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.launchView, done, {a11yReport: true})
})

test('calls render on return view when launch button clicked', function() {
  this.stub(this.mockReturnView, 'render').returns(this)
  this.launchView.$el.find('#externalToolLaunch').click()
  ok(this.mockReturnView.render.calledOnce, 'render not called on return view')
})

test("displays file name on 'ready'", function() {
  this.mockReturnView.trigger('ready', {
    contentItems: [
      {
        text: 'data text',
        url: 'data url'
      }
    ]
  })
  strictEqual(this.launchView.$fileName.text(), 'data text')
})

test("sets settings.data_url on migration on 'ready'", function() {
  this.mockReturnView.trigger('ready', {
    contentItems: [
      {
        text: 'data text',
        url: 'data url'
      }
    ]
  })
  deepEqual(this.mockMigration.get('settings'), {file_url: 'data url'})
})
