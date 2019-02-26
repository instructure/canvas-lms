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
import {render, fireEvent} from 'react-testing-library'
import AssignmentName from '../AssignmentName'

describe('AssignmentName', () => {
  it('renders the value in view mode', () => {
    const {getByText} = render(
      <AssignmentName mode="view" onChange={() => {}} onChangeMode={() => {}} name="the name" />
    )

    expect(getByText('the name')).toBeInTheDocument()
  })

  it('renders the value in edit mode', () => {
    const {container} = render(
      <AssignmentName mode="edit" onChange={() => {}} onChangeMode={() => {}} name="the name" />
    )

    expect(container.querySelector('input[value="the name"]')).toBeInTheDocument()
  })

  it('shows error message with invalid value', () => {
    const {getByText} = render(
      <AssignmentName mode="edit" onChange={() => {}} onChangeMode={() => {}} name="" />
    )

    expect(getByText('Assignment name is required')).toBeInTheDocument()
  })

  it('shows the placeholder when the value is empty', () => {
    const {getByText} = render(
      <AssignmentName mode="view" onChange={() => {}} onChangeMode={() => {}} name="" />
    )

    expect(getByText('Assignment name')).toBeInTheDocument()
    expect(getByText('Assignment name is required')).toBeInTheDocument()
  })

  it('does not leave edit mode if missing the name', () => {
    const onchangemode = jest.fn()
    const {container, getByText} = render(
      <div>
        <AssignmentName mode="edit" onChange={() => {}} onChangeMode={onchangemode} name="" />
        <span id="click-me" tabIndex="-1">
          just here to get focus
        </span>
      </div>
    )

    const nameinput = container.querySelector('[data-testid="AssignmentName"] input')
    nameinput.click()
    container.querySelector('#click-me').focus()
    expect(onchangemode).not.toHaveBeenCalled()
    expect(getByText('Assignment name is required')).toBeInTheDocument()
  })

  it('saves new value on Enter', () => {
    const onChange = jest.fn()
    const onChangeMode = jest.fn()
    const {container} = render(
      <AssignmentName mode="edit" onChange={onChange} onChangeMode={onChangeMode} name="the name" />
    )

    const input = container.querySelector('input[value="the name"]')
    fireEvent.input(input, {target: {value: 'x'}})
    fireEvent.keyDown(input, {key: 'Enter', code: 13})
    expect(onChangeMode).toHaveBeenCalledWith('view')
    expect(onChange).toHaveBeenCalledWith('x')
  })

  it('reverts to the old value on Escape', () => {
    const onChange = jest.fn()
    const {container} = render(
      <AssignmentName mode="edit" onChange={onChange} onChangeMode={() => {}} name="the name" />
    )

    const input = container.querySelector('input[value="the name"]')
    fireEvent.input(input, {target: {value: 'x'}})
    fireEvent.keyDown(input, {key: 'Escape', code: 27})
    expect(onChange).toHaveBeenCalledWith('x')
    expect(onChange).toHaveBeenCalledWith('the name')
  })
})
