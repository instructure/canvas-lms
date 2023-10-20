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
import AssignmentPoints from '../AssignmentPoints'
import AssignmentFieldValidator from '../../../AssignentFieldValidator'

const afv = new AssignmentFieldValidator()
function validate() {
  return afv.validate(...arguments)
}
function errorMessage() {
  return afv.errorMessage(...arguments)
}

function renderAssignmentPoints(props) {
  return render(
    <AssignmentPoints
      mode="view"
      onChange={() => {}}
      onChangeMode={() => {}}
      onValidate={validate}
      invalidMessage={errorMessage}
      pointsPossible={1432}
      {...props}
    />
  )
}

describe('AssignmentPoints', () => {
  it('renders the value in view mode', () => {
    const {getAllByText} = renderAssignmentPoints()

    expect(getAllByText('1432')[0]).toBeInTheDocument()
  })

  it('renders the value in edit mode', () => {
    const {getByDisplayValue} = renderAssignmentPoints({mode: 'edit'})

    expect(getByDisplayValue('1432')).toBeInTheDocument()
  })

  it('shows error message with invalid value', () => {
    const {getByText} = renderAssignmentPoints({pointsPossible: '1432x'})

    expect(getByText('Points must be a number >= 0')).toBeInTheDocument()
  })

  it('saves new value on Enter', () => {
    const onChange = jest.fn()
    const {getByDisplayValue} = renderAssignmentPoints({mode: 'edit', onChange, pointsPossible: 12})

    const input = getByDisplayValue('12')
    fireEvent.input(input, {target: {value: '7'}})
    fireEvent.keyDown(input, {key: 'Enter', code: 13})
    expect(onChange).toHaveBeenCalledWith('7')
  })

  it('saves new value on blur', () => {
    const onChange = jest.fn()
    const onChangeMode = jest.fn()
    const {container, getByDisplayValue} = render(
      <div>
        <AssignmentPoints
          mode="edit"
          onChange={onChange}
          onChangeMode={onChangeMode}
          onValidate={() => true}
          invalidMessage={() => undefined}
          pointsPossible={12}
        />
        <span id="focus-me" tabIndex="-1">
          just here to get focus
        </span>
      </div>
    )

    const input = getByDisplayValue('12')
    fireEvent.input(input, {target: {value: '7'}})
    container.querySelector('#focus-me').focus()
    expect(onChange).toHaveBeenCalledWith('7')
    expect(onChangeMode).toHaveBeenCalledWith('view')
  })

  it('reverts to the old value on Escape', () => {
    const onChange = jest.fn()
    const {getByDisplayValue} = renderAssignmentPoints({mode: 'edit', onChange, pointsPossible: 12})

    const input = getByDisplayValue('12')
    fireEvent.input(input, {target: {value: '7'}})
    fireEvent.keyDown(input, {key: 'Escape', code: 27})
    expect(onChange).toHaveBeenCalledWith('7')
    expect(onChange).toHaveBeenCalledWith(12)
  })

  it('rounds to 2 decimal places', () => {
    const onChange = jest.fn()
    const {getByTestId} = render(
      <div>
        <AssignmentPoints
          mode="edit"
          onChange={onChange}
          onChangeMode={() => {}}
          onValidate={validate}
          invalidMessage={errorMessage}
          pointsPossible="1.247"
        />
        <input data-testid="focusme" />
      </div>
    )
    const btn = getByTestId('focusme')
    btn.focus()
    expect(onChange).toHaveBeenCalledWith(1.25)
  })
})
