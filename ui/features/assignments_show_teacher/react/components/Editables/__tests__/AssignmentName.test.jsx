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
import {render, fireEvent} from '@testing-library/react'
import AssignmentName from '../AssignmentName'
import AssignmentFieldValidator from '../../../AssignentFieldValidator'

const afv = new AssignmentFieldValidator()
function validate() {
  return afv.validate(...arguments)
}
function errorMessage() {
  return afv.errorMessage(...arguments)
}

function renderAssignmentName(props) {
  return render(
    <AssignmentName
      mode="view"
      onChange={() => {}}
      onChangeMode={() => {}}
      onValidate={validate}
      invalidMessage={errorMessage}
      name="the name"
      {...props}
    />
  )
}

describe('AssignmentName', () => {
  it('renders the value in view mode', () => {
    const {getAllByText} = renderAssignmentName()

    expect(getAllByText('the name')[0]).toBeInTheDocument()
  })

  it('renders the value in edit mode', () => {
    const {getByDisplayValue} = renderAssignmentName({mode: 'edit'})

    expect(getByDisplayValue('the name')).toBeInTheDocument()
  })

  it('shows error message with invalid value', () => {
    const {getByText} = renderAssignmentName({mode: 'edit', name: ''})

    expect(getByText('Assignment name is required')).toBeInTheDocument()
  })

  it('shows the placeholder when the value is empty', () => {
    const {getByText} = renderAssignmentName({name: ''})

    expect(getByText('Assignment name')).toBeInTheDocument()
    expect(getByText('Assignment name is required')).toBeInTheDocument()
  })

  it('saves new value on Enter', () => {
    const onChange = jest.fn()
    const onChangeMode = jest.fn()
    const {getByDisplayValue} = renderAssignmentName({
      mode: 'edit',
      onChange,
      onChangeMode,
    })

    const input = getByDisplayValue('the name')
    fireEvent.input(input, {target: {value: 'x'}})
    fireEvent.keyDown(input, {key: 'Enter', code: 13})
    expect(onChangeMode).toHaveBeenCalledWith('view')
    expect(onChange).toHaveBeenCalledWith('x')
  })

  it('saves the new value on blur', () => {
    const onChange = jest.fn()
    const onChangeMode = jest.fn()
    const {container, getByDisplayValue} = render(
      <div>
        <AssignmentName
          mode="edit"
          onChange={onChange}
          onChangeMode={onChangeMode}
          onValidate={() => true}
          invalidMessage={() => undefined}
          name="the name"
        />
        <span id="focus-me" tabIndex="-1">
          just here to get focus
        </span>
      </div>
    )

    const input = getByDisplayValue('the name')
    fireEvent.input(input, {target: {value: 'new name'}})
    container.querySelector('#focus-me').focus()

    expect(onChangeMode).toHaveBeenCalledWith('view')
    expect(onChange).toHaveBeenCalledWith('new name')
  })
})
