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
import _ from 'lodash'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomeDialogView from 'ui/features/grade_summary/backbone/views/OutcomeDialogView'
import OutcomeLineGraphView from 'ui/features/grade_summary/backbone/views/OutcomeLineGraphView'

QUnit.module('OutcomeDialogViewSpec', {
  setup() {
    this.outcomeDialogView = new OutcomeDialogView({model: new Outcome()})
    this.e = function (name, options = {}) {
      return $.Event(name, Object.assign(options, {currentTarget: this.outcomeDialogView.el}))
    }
  },
})

test('assign instance of OutcomeLineGraphView on init', function () {
  ok(this.outcomeDialogView.outcomeLineGraphView instanceof OutcomeLineGraphView)
})

test('afterRender', function () {
  const setElementSpy = sandbox.stub(this.outcomeDialogView.outcomeLineGraphView, 'setElement')
  const renderSpy = sandbox.stub(this.outcomeDialogView.outcomeLineGraphView, 'render')

  this.outcomeDialogView.render()

  ok(setElementSpy.called, 'should set linegraph element')
  ok(renderSpy.called, 'should render line graph')
})

test('#show', function () {
  const renderSpy = sandbox.stub(this.outcomeDialogView, 'render')
  const dialogSpy = sandbox.stub(this.outcomeDialogView.$el, 'dialog')

  this.outcomeDialogView.show(this.e('mouseenter'))
  ok(!renderSpy.called, 'should not render on any event')
  ok(!dialogSpy.called, 'should not open dialog on any event')

  // enter; space
  _.each([13, 32], i => {
    this.outcomeDialogView.show(this.e('mouseenter', {keyCode: i}))
    ok(renderSpy.called, `should render with keyCode ${i}`)
    ok(dialogSpy.called, `should open dialog with keyCode ${i}`)
    renderSpy.reset()
    dialogSpy.reset()
  })

  // backspace; escape
  _.each([8, 27], i => {
    this.outcomeDialogView.show(this.e('mouseenter', {keyCode: i}))
    ok(!renderSpy.called, `should not render with keyCode ${i}`)
    ok(!dialogSpy.called, `should not open dialog with keyCode ${i}`)
  })

  this.outcomeDialogView.show(this.e('click'))
  ok(renderSpy.called, 'should render with click')
  ok(dialogSpy.called, 'should open dialog with click')
  renderSpy.reset()
  dialogSpy.reset()
})

test('toJSON', function () {
  ok(this.outcomeDialogView.toJSON().dialog, 'should include dialog key')
})
