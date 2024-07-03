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
import DueDateAddRowButton from '../DueDateAddRowButton'

describe('DueDateAddRowButton with true display prop', () => {
  let DueDateAddRowButtonInstance

  beforeEach(() => {
    const props = {display: true}
    const DueDateAddRowButtonElement = <DueDateAddRowButton {...props} />
    DueDateAddRowButtonInstance = ReactDOM.render(
      DueDateAddRowButtonElement,
      $('<div>').appendTo('body')[0]
    )
  })

  afterEach(() => {
    if (ReactDOM.findDOMNode(DueDateAddRowButtonInstance)) {
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(DueDateAddRowButtonInstance).parentNode)
    }
  })

  test('renders a button', () => {
    expect(DueDateAddRowButtonInstance).toBeTruthy()
    expect(DueDateAddRowButtonInstance.addButtonRef).toBeTruthy()
  })
})

describe('DueDateAddRowButton with false display prop', () => {
  let DueDateAddRowButtonInstance

  beforeEach(() => {
    const props = {display: false}
    const DueDateAddRowButtonElement = <DueDateAddRowButton {...props} />
    DueDateAddRowButtonInstance = ReactDOM.render(
      DueDateAddRowButtonElement,
      $('<div>').appendTo('body')[0]
    )
  })

  afterEach(() => {
    if (ReactDOM.findDOMNode(DueDateAddRowButtonInstance)) {
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(DueDateAddRowButtonInstance).parentNode)
    }
  })

  test('does not render a button', () => {
    expect(DueDateAddRowButtonInstance).toBeTruthy()
    expect(DueDateAddRowButtonInstance.addButtonRef).toBeFalsy()
  })
})
