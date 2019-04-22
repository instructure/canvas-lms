/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render} from 'react-testing-library'
import AssignmentType from '../AssignmentType'

beforeAll(() => {
  global.window.ENV = {}
})

it('renders the given assignment type in view mode', () => {
  const {getByText, getByTestId} = render(
    <AssignmentType
      mode="view"
      onChange={() => {}}
      onChangeMode={() => {}}
      selectedAssignmentType="group"
    />
  )
  expect(getByTestId('SelectableText')).toBeInTheDocument()
  expect(getByText('Group Assignment')).toBeInTheDocument()
})

it('renders the given assignment type in edit mode', () => {
  const {getByTestId} = render(
    <AssignmentType
      mode="edit"
      onChange={() => {}}
      onChangeMode={() => {}}
      selectedAssignmentType="group"
    />
  )
  expect(getByTestId('SelectableText')).toBeInTheDocument()
  expect(document.querySelector('input').value).toBe('Group Assignment')
})

it('renders the placeholder when not given a value', () => {
  const {getByText, getByTestId} = render(
    <AssignmentType mode="view" onChange={() => {}} onChangeMode={() => {}} />
  )
  expect(getByTestId('SelectableText')).toBeInTheDocument()
  expect(getByText('Assignment Type')).toBeInTheDocument()
})

it('has 3 options if quiz.next is not enabled', () => {
  const {container} = render(
    <AssignmentType
      mode="edit"
      onChange={() => {}}
      onChangeMode={() => {}}
      selectedAssignmentType="assignment"
    />
  )
  const input = container.querySelector('input')
  input.click()
  expect(document.querySelectorAll('li[role="option"]')).toHaveLength(3)
})

it('has 4 options if quiz.next is enabled', () => {
  global.window.ENV.QUIZ_LTI_ENABLED = true
  const {container} = render(
    <AssignmentType
      mode="edit"
      onChange={() => {}}
      onChangeMode={() => {}}
      selectedAssignmentType="assignment"
    />
  )
  const input = container.querySelector('input')
  input.click()
  expect(document.querySelectorAll('li[role="option"]')).toHaveLength(4)
})

it('calls onChange when the selection changes', () => {
  const onchange = jest.fn()
  const onchangemode = jest.fn()
  const {container} = render(
    <div>
      <AssignmentType
        mode="edit"
        onChange={onchange}
        onChangeMode={onchangemode}
        selectedAssignmentType="assignment"
      />
      <span id="focus-me" tabIndex="-1">
        just here to get focus
      </span>
    </div>
  )
  const input = container.querySelector('input')
  input.click()
  const option = document.querySelectorAll('li[role="option"]')[1]
  option.click()
  container.querySelector('#focus-me').focus()
  expect(onchangemode).toHaveBeenCalledWith('view')
  expect(onchange).not.toHaveBeenCalled()

  // it takes a re-render in view to get onChange called
  render(
    <div>
      <AssignmentType
        mode="view"
        onChange={onchange}
        onChangeMode={onchangemode}
        selectedAssignmentType="peer-review"
      />
      <span id="click-me" tabIndex="-1">
        just here to get focus
      </span>
    </div>,
    {container}
  )
  expect(onchange).toHaveBeenCalledWith('peer-review')
})
