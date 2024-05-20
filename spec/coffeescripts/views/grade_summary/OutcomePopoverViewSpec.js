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
import Popover from 'jquery-popover'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomePopoverView from 'ui/features/grade_summary/backbone/views/OutcomePopoverView'
import template from '@canvas/outcomes/jst/outcomePopover.handlebars'

QUnit.module('OutcomePopoverViewSpec', {
  setup() {
    $(document.body).append('<div id="application"></div>')
    this.popoverView = new OutcomePopoverView({
      el: $('<div><i></i></div>'),
      model: new Outcome(),
      template,
    })
    this.e = function (name, options = {}) {
      return $.Event(name, {...options, currentTarget: this.popoverView.el})
    }
    this.clock = sinon.useFakeTimers()
  },
  teardown() {
    this.clock.restore()
  },
})

test('closePopover', function () {
  ok(isUndefined(this.popoverView.popover), 'precondition')
  ok(this.popoverView.closePopover())
  this.popoverView.popover = new Popover(this.e('mouseleave'), this.popoverView.render(), {
    verticalSide: 'bottom',
    manualOffset: 14,
  })
  ok(this.popoverView.popover instanceof Popover)
  ok(this.popoverView.closePopover())
  ok(isUndefined(this.popoverView.popover))
})

test('mouseenter', function () {
  const spy = sandbox.spy(this.popoverView, 'openPopover')
  ok(!this.popoverView.inside, 'precondition')
  this.popoverView.el.find('i').trigger(this.e('mouseenter'))
  ok(spy.called)
  ok(this.popoverView.inside)
})

test('mouseleave when no popover is present', function () {
  const spy = sandbox.spy(this.popoverView, 'closePopover')
  ok(isUndefined(this.popoverView.popover), 'precondition')
  this.popoverView.el.find('i').trigger(this.e('mouseleave'))
  this.clock.tick(this.popoverView.TIMEOUT_LENGTH)
  ok(!spy.called)
})

test('mouseleave when popover is present', function () {
  this.popoverView.el.find('i').trigger('mouseenter')
  ok(!isUndefined(this.popoverView.popover), 'precondition')
  ok(this.popoverView.inside, 'precondition')
  const spy = sandbox.spy(this.popoverView, 'closePopover')
  this.popoverView.el.find('i').trigger(this.e('mouseleave'))
  this.clock.tick(this.popoverView.TIMEOUT_LENGTH)
  ok(spy.called)
})

test('openPopover', function () {
  ok(isUndefined(this.popoverView.popover), 'precondition')
  const elementSpy = sandbox.stub(this.popoverView.outcomeLineGraphView, 'setElement')
  const renderSpy = sandbox.stub(this.popoverView.outcomeLineGraphView, 'render')
  this.popoverView.openPopover(this.e('mouseenter'))
  ok(this.popoverView.popover instanceof Popover)
  ok(elementSpy.called)
  ok(renderSpy.called)
})
