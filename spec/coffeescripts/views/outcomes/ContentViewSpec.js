/* eslint-disable qunit/resolve-async */
/* eslint-disable  no-undef */
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
import 'jquery-migrate'
import ContentView from '@canvas/outcomes/content-view/backbone/views/index'
import fakeENV from 'helpers/fakeENV'
import instructionsTemplate from 'ui/features/learning_outcomes/jst/mainInstructions.handlebars'
import assertions from 'helpers/assertions'
import {publish} from 'jquery-tinypubsub'

QUnit.module('CollectionView', {
  setup() {
    fakeENV.setup()
    const viewEl = $('<div id="content-view-el">original_text</div>')
    viewEl.appendTo(fixtures)
    this.contentView = new ContentView({
      el: viewEl,
      instructionsTemplate,
      renderengInstructions: false,
    })
    this.contentView.$el.appendTo($('#fixtures'))
    this.contentView.render()
  },
  teardown() {
    fakeENV.teardown()
    this.contentView.remove()
  },
})

test('should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.contentView, done, {a11yReport: true})
})

test('collectionView replaces text with warning and link on renderNoOutcomeWarning event', function () {
  ok(this.contentView.$el.text().match(/original_text/))
  publish('renderNoOutcomeWarning')
  ok(this.contentView.$el.text().match(/You have no outcomes/))
  ok(!this.contentView.$el.text().match(/original_text/))
  ok(
    this.contentView.$el
      .find('a')
      .attr('href')
      .search(`${this.contentView._contextPath()}/outcomes`) > 0
  )
})
