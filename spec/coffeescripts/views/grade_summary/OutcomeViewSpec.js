/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {isUndefined} from 'lodash'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomePopoverView from 'ui/features/grade_summary/backbone/views/OutcomePopoverView'
import OutcomeDialogView from 'ui/features/grade_summary/backbone/views/OutcomeDialogView'
import OutcomeView from 'ui/features/grade_summary/backbone/views/OutcomeView'
import ProgressBarView from 'ui/features/grade_summary/backbone/views/ProgressBarView'
import assertions from 'helpers/assertions'

QUnit.module('OutcomeViewSpec', {
  setup() {
    this.outcomeView = new OutcomeView({
      el: $('<li><a class="more-details"></a></li>'),
      model: new Outcome(),
    })
    this.e = function (name, options = {}) {
      return $.Event(name, {...options, currentTarget: this.outcomeView.$el.find('a.more-details')})
    }
  },
})

// eslint-disable-next-line qunit/resolve-async
test('should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.outcomeView, done, {a11yReport: true})
})

test('assign instance of ProgressBarView on init', function () {
  ok(this.outcomeView.progress instanceof ProgressBarView)
})

test('have after render behavior', function () {
  ok(isUndefined(this.outcomeView.popover), 'precondition')
  this.outcomeView.render()
  ok(this.outcomeView.popover instanceof OutcomePopoverView)
  ok(this.outcomeView.dialog instanceof OutcomeDialogView)
})

test('click & keydown .more-details', function () {
  this.outcomeView.render()
  const showSpy = sandbox.stub(this.outcomeView.dialog, 'show')
  this.outcomeView.$el.find('a.more-details').trigger(this.e('click'))
  ok(showSpy.called)
  showSpy.reset()
  this.outcomeView.$el.find('a.more-details').trigger(this.e('keydown'))
  ok(showSpy.called)
})
