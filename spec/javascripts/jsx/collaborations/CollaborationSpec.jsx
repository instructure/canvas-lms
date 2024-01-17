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
import TestUtils from 'react-dom/test-utils'
import ReactDOM from 'react-dom'
import Collaboration from 'ui/features/lti_collaborations/react/Collaboration'
import * as tz from '@canvas/datetime'

QUnit.module('Collaboration')

const props = {
  collaboration: {
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
    update_url: 'http://google.com',
    id: 1,
    permissions: {
      update: true,
      delete: true,
    },
  },
}

test('renders the collaboration', () => {
  ENV.context_asset_string = 'courses_1'

  const component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
  const title = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-title')
  ).innerText
  const description = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-description')
  ).innerText
  const author = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author')
  ).innerText
  const updateDate = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay')
  ).innerText

  equal(title, props.collaboration.title)
  equal(description, props.collaboration.description)
  equal(author, `${props.collaboration.user_name},`)
  ok(updateDate)
})

test('renders a link to the user who created the collaboration', () => {
  ENV.context_asset_string = 'courses_1'

  const component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
  const link = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author')
  )
  ok(link.href.includes('/users/1'))
})

test('renders the date time in the correct format', () => {
  ENV.context_asset_string = 'courses_1'

  const component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
  const dateString = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay')
  ).innerText
  equal(dateString, tz.format(props.collaboration.updated_at, '%b %d, %l:%M %p'))
})

test('when the user clicks the trash button it opens the delete confirmation', () => {
  ENV.context_asset_string = 'courses_1'

  const component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
  const trashIcon = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'icon-trash')
  )
  TestUtils.Simulate.click(trashIcon)
  const deleteConfirmation = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'DeleteConfirmation'
  )
  ok(deleteConfirmation)
})

test('when the user clicks the cancel button on the delete confirmation it removes the delete confirmation', () => {
  ENV.context_asset_string = 'courses_1'

  const component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
  const trashIcon = ReactDOM.findDOMNode(
    TestUtils.findRenderedDOMComponentWithClass(component, 'icon-trash')
  )
  TestUtils.Simulate.click(trashIcon)
  const cancelButton = ReactDOM.findDOMNode(
    TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[1]
  )
  TestUtils.Simulate.click(cancelButton)
  const deleteConfirmation = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'DeleteConfirmation'
  )
  equal(deleteConfirmation.length, 0)
})

test('has an edit button that links to the proper url', () => {
  ENV.context_asset_string = 'courses_1'

  const component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
  const editIcon = TestUtils.findRenderedDOMComponentWithClass(component, 'icon-edit')
  ok(
    ReactDOM.findDOMNode(editIcon).href.includes(
      `/courses/1/lti_collaborations/external_tools/retrieve?content_item_id=${props.collaboration.id}&placement=collaboration&url=${props.collaboration.update_url}&display=borderless`
    )
  )
})
