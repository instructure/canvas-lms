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
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import _ from 'lodash'
import DashboardCardAction from '@canvas/dashboard-card/react/DashboardCardAction'

QUnit.module('DashboardCardAction', {
  setup() {
    this.props = {
      iconClass: 'icon-assignment',
      path: '/courses/1/assignments/',
    }
  },
  teardown() {
    if (this.component) {
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.component).parentNode)
    }
  },
})

test('should render link & icon', function () {
  this.component = TestUtils.renderIntoDocument(<DashboardCardAction {...this.props} />)
  const $html = $(ReactDOM.findDOMNode(this.component))
  equal($html.prop('tagName'), 'A', 'parent tag should be link')
  equal($html.find('svg').attr('name'), 'IconAssignment', 'should have provided corresponding icon')
  equal($html.find('span.screenreader-only').length, 0, 'should not have screenreader span')
})

test('should render fallback icon for unrecognized iconClass', function () {
  this.props.iconClass = 'icon-something-else'
  this.component = TestUtils.renderIntoDocument(<DashboardCardAction {...this.props} />)
  const $html = $(ReactDOM.findDOMNode(this.component))
  equal($html.prop('tagName'), 'A', 'parent tag should be link')
  equal(
    $html.find('i').attr('class'),
    this.props.iconClass,
    'i tag should have given prop as class'
  )
  equal($html.find('span.screenreader-only').length, 0, 'should not have screenreader span')
})

test('should render actionType as screenreader text if provided', function () {
  const screen_reader_label = 'Dashboard Action'
  const component = TestUtils.renderIntoDocument(
    <DashboardCardAction {...this.props} screenReaderLabel={screen_reader_label} />
  )
  const $html = $(ReactDOM.findDOMNode(component))
  equal($html.find('span.screenreader-only').text(), screen_reader_label)
})

test('should display unread count when it is greater than zero', function () {
  const unread_count = 2
  this.component = TestUtils.renderIntoDocument(
    <DashboardCardAction {...this.props} unreadCount={unread_count} />
  )
  const $html = $(ReactDOM.findDOMNode(this.component))
  equal($html.find('span.unread_count').text(), unread_count, 'should display unread count')
  equal(
    $html.find('span.screenreader-only').text(),
    'Unread',
    'should display Unread as screenreader only text'
  )
})
