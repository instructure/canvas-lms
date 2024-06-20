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
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import DashboardCardAction from '../DashboardCardAction'

const equal = (x, y) => expect(x).toBe(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let props
let component

describe('DashboardCardAction', () => {
  beforeAll(() => {
    props = {
      iconClass: 'icon-assignment',
      path: '/courses/1/assignments/',
    }
  })

  test('should render link & icon', function () {
    component = TestUtils.renderIntoDocument(<DashboardCardAction {...props} />)
    const $html = $(ReactDOM.findDOMNode(component))
    equal($html.prop('tagName'), 'A', 'parent tag should be link')
    equal(
      $html.find('svg').attr('name'),
      'IconAssignment',
      'should have provided corresponding icon'
    )
    equal($html.find('span.screenreader-only').length, 0, 'should not have screenreader span')
  })

  test('should render fallback icon for unrecognized iconClass', function () {
    props.iconClass = 'icon-something-else'
    component = TestUtils.renderIntoDocument(<DashboardCardAction {...props} />)
    const $html = $(ReactDOM.findDOMNode(component))
    equal($html.prop('tagName'), 'A', 'parent tag should be link')
    equal($html.find('i').attr('class'), props.iconClass, 'i tag should have given prop as class')
    equal($html.find('span.screenreader-only').length, 0, 'should not have screenreader span')
  })

  test('should render actionType as screenreader text if provided', function () {
    const screen_reader_label = 'Dashboard Action'
    const component = TestUtils.renderIntoDocument(
      <DashboardCardAction {...props} screenReaderLabel={screen_reader_label} />
    )
    const $html = $(ReactDOM.findDOMNode(component))
    equal($html.find('span.screenreader-only').text(), screen_reader_label)
  })

  test('should display unread count when it is greater than zero', function () {
    const unread_count = 2
    component = TestUtils.renderIntoDocument(
      <DashboardCardAction {...props} unreadCount={unread_count} />
    )
    const $html = $(ReactDOM.findDOMNode(component))
    equal(
      $html.find('span.unread_count').text(),
      String(unread_count),
      'should display unread count'
    )
    equal(
      $html.find('span.screenreader-only').text(),
      'Unread',
      'should display Unread as screenreader only text'
    )
  })

  if (component) {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  }
})
