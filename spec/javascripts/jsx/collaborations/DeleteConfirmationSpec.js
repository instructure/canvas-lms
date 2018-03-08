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

define(
  ['react', 'react-addons-test-utils', 'jsx/collaborations/DeleteConfirmation'],
  (React, TestUtils, DeleteConfirmation) => {
    QUnit.module('DeleteConfirmation')

    let props = {
      collaboration: {
        title: 'Hello there',
        description: 'Im here to describe stuff',
        user_id: 1,
        user_name: 'Say my name',
        updated_at: new Date(0).toString()
      },
      onDelete: () => {},
      onCancel: () => {}
    }

    test('renders the message and action buttons', () => {
      let component = TestUtils.renderIntoDocument(<DeleteConfirmation {...props} />)
      let message = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'DeleteConfirmation-message'
      )
      let buttons = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')

      equal(message.getDOMNode().innerText, 'Remove "Hello there"?')
      equal(buttons.length, 2)
      equal(buttons[0].getDOMNode().innerText, 'Yes, remove')
      equal(buttons[1].getDOMNode().innerText, 'Cancel')
    })

    test('Clicking on the confirmation button calls onDelete', () => {
      let onDeleteCalled = false
      let newProps = {
        ...props,
        onDelete: () => {
          onDeleteCalled = true
        }
      }

      let component = TestUtils.renderIntoDocument(<DeleteConfirmation {...newProps} />)
      let confirmButton = TestUtils.scryRenderedDOMComponentsWithClass(
        component,
        'Button'
      )[0].getDOMNode()
      TestUtils.Simulate.click(confirmButton)
      ok(onDeleteCalled)
    })

    test('Clicking on the cancel button calls onCancel', () => {
      let onCancelCalled = false
      let newProps = {
        ...props,
        onCancel: () => {
          onCancelCalled = true
        }
      }

      let component = TestUtils.renderIntoDocument(<DeleteConfirmation {...newProps} />)
      let cancelButton = TestUtils.scryRenderedDOMComponentsWithClass(
        component,
        'Button'
      )[1].getDOMNode()
      TestUtils.Simulate.click(cancelButton)
      ok(onCancelCalled)
    })
  }
)
