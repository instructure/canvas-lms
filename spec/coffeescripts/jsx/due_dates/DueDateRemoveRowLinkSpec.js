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
import {Simulate} from 'react-addons-test-utils'
import DueDateRemoveRowLink from 'jsx/due_dates/DueDateRemoveRowLink'

QUnit.module('DueDateRemoveRowLink', {
  setup() {
    const props = {
      handleClick() {}
    }
    this.handleClick = sandbox.stub(props, 'handleClick')
    const DueDateRemoveRowLinkElement = <DueDateRemoveRowLink {...props} />
    this.DueDateRemoveRowLink = ReactDOM.render(
      DueDateRemoveRowLinkElement,
      $('<div>').appendTo('body')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.DueDateRemoveRowLink).parentNode)
  }
})

test('renders', function() {
  ok(this.DueDateRemoveRowLink)
})

test('calls handleClick prop when clicked', function() {
  Simulate.click(this.DueDateRemoveRowLink.refs.removeRowIcon)
  ok(this.handleClick.calledOnce)
})
