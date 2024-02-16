/* eslint-disable qunit/resolve-async */
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

import SpeedgraderLinkView from 'ui/features/assignment_show/backbone/views/SpeedgraderLinkView'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import $ from 'jquery'
import 'jquery-migrate'
import assertions from 'helpers/assertions'

QUnit.module('SpeedgraderLinkView', {
  setup() {
    this.model = new Assignment({published: false})
    $('#fixtures').html(`\
<ul><li id="assignment-speedgrader-link" class="hidden"></li></ul>\
`)
    this.view = new SpeedgraderLinkView({
      model: this.model,
      el: $('#fixtures').find('#assignment-speedgrader-link'),
    })
    return this.view.render()
  },
  teardown() {
    this.view.remove()
    $('#fixtures').empty()
  },
})

test('it should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.view, done, {a11yReport: true})
})

test('#toggleSpeedgraderLink toggles visibility of speedgrader link on change', function () {
  this.model.set('published', true)
  ok(!this.view.$el.hasClass('hidden'))
  this.model.set('published', false)
  ok(this.view.$el.hasClass('hidden'))
})
