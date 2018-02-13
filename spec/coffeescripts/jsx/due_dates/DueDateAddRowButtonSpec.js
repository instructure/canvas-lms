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
import {Simulate, SimulateNative} from 'react-addons-test-utils'
import DueDateAddRowButton from 'jsx/due_dates/DueDateAddRowButton'

QUnit.module('DueDateAddRowButton with true display prop', {
  setup() {
    const props = {display: true}
    const DueDateAddRowButtonElement = <DueDateAddRowButton {...props} />
    this.DueDateAddRowButton = ReactDOM.render(
      DueDateAddRowButtonElement,
      $('<div>').appendTo('body')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.DueDateAddRowButton.getDOMNode().parentNode)
  }
})

test('renders a button', function() {
  ok(this.DueDateAddRowButton.isMounted())
  ok(this.DueDateAddRowButton.refs.addButton)
})

QUnit.module('DueDateAddRowButton with false display prop', {
  setup() {
    const props = {display: false}
    const DueDateAddRowButtonElement = <DueDateAddRowButton {...props} />
    this.DueDateAddRowButton = ReactDOM.render(
      DueDateAddRowButtonElement,
      $('<div>').appendTo('body')[0]
    )
  },
  teardown() {
    if (this.DueDateAddRowButton.getDOMNode()) {
      ReactDOM.unmountComponentAtNode(this.DueDateAddRowButton.getDOMNode().parentNode)
    }
  }
})

test('does not render a button', function() {
  ok(this.DueDateAddRowButton.isMounted())
  ok(!this.DueDateAddRowButton.refs.addButton)
})
