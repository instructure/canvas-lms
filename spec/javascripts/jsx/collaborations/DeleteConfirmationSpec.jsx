/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import DeleteConfirmation from 'ui/features/lti_collaborations/react/DeleteConfirmation'

QUnit.module('DeleteConfirmation')

const props = {
  collaboration: {
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
  },
  onDelete: () => {},
  onCancel: () => {},
}

test('renders the message and action buttons', () => {
  const component = TestUtils.renderIntoDocument(<DeleteConfirmation {...props} />)
  const message = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'DeleteConfirmation-message'
  )
  const buttons = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')

  equal(ReactDOM.findDOMNode(message).innerText, 'Remove "Hello there"?')
  equal(buttons.length, 2)
  equal(ReactDOM.findDOMNode(buttons[0]).innerText, 'Yes, remove')
  equal(ReactDOM.findDOMNode(buttons[1]).innerText, 'Cancel')
})

test('Clicking on the confirmation button calls onDelete', () => {
  let onDeleteCalled = false
  const newProps = {
    ...props,
    onDelete: () => {
      onDeleteCalled = true
    },
  }

  const component = TestUtils.renderIntoDocument(<DeleteConfirmation {...newProps} />)
  const confirmButton = ReactDOM.findDOMNode(
    TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[0]
  )
  TestUtils.Simulate.click(confirmButton)
  ok(onDeleteCalled)
})

test('Clicking on the cancel button calls onCancel', () => {
  let onCancelCalled = false
  const newProps = {
    ...props,
    onCancel: () => {
      onCancelCalled = true
    },
  }

  const component = TestUtils.renderIntoDocument(<DeleteConfirmation {...newProps} />)
  const cancelButton = ReactDOM.findDOMNode(
    TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[1]
  )
  TestUtils.Simulate.click(cancelButton)
  ok(onCancelCalled)
})
