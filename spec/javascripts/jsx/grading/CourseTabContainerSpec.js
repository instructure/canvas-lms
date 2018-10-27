/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'

import {mount} from 'enzyme'
import $ from 'jquery'
import _ from 'underscore'
import CourseTabContainer from 'jsx/grading/CourseTabContainer'
import 'jqueryui/tabs'

QUnit.module('CourseTabContainer', {
  renderComponent(props = {}) {
    const defaults = {}
    const mergedProps = _.defaults(props, defaults)

    this.wrapper = mount(React.createElement(CourseTabContainer, mergedProps))
  },

  setup() {
    sandbox.stub($, 'getJSON').returns({success: () => ({error: () => {}}), done: () => {}})
  },

  teardown() {
    this.wrapper.unmount()
  }
})

test('tabs are present when there are grading periods', function() {
  this.renderComponent({hasGradingPeriods: true})
  const $el = this.wrapper.getDOMNode()
  strictEqual($el.querySelectorAll('.ui-tabs').length, 1)
  strictEqual($el.querySelectorAll('.ui-tabs ul.ui-tabs-nav li').length, 2)
  equal($el.querySelector('#grading-periods-tab').getAttribute('style'), 'display: block;')
  equal($el.querySelector('#grading-standards-tab').getAttribute('style'), 'display: none;')
})

test('tabs are not present when there are no grading periods', function() {
  this.renderComponent({hasGradingPeriods: false})
  equal(this.wrapper.find('.ui-tabs').length, 0)
})

test('jquery-ui tabs() is called when there are grading periods', function() {
  const tabsSpy = sandbox.spy($.fn, 'tabs')
  this.renderComponent({hasGradingPeriods: true})
  ok(tabsSpy.calledOnce)
})

test('jquery-ui tabs() is not called when there are no grading periods', function() {
  const tabsSpy = sandbox.spy($.fn, 'tabs')
  this.renderComponent({hasGradingPeriods: false})
  notOk(tabsSpy.called)
})

test('does not render grading periods if there are no grading periods', function() {
  this.renderComponent({hasGradingPeriods: false})
  notOk(this.wrapper.instance().gradingPeriods)
})

test('renders the grading periods if there are grading periods', function() {
  this.renderComponent({hasGradingPeriods: true})
  ok(this.wrapper.instance().gradingPeriods)
})

test('renders the grading standards if there are no grading periods', function() {
  this.renderComponent({hasGradingPeriods: false})
  ok(this.wrapper.instance().gradingStandards)
})

test('renders the grading standards if there are grading periods', function() {
  this.renderComponent({hasGradingPeriods: true})
  ok(this.wrapper.instance().gradingStandards)
})
