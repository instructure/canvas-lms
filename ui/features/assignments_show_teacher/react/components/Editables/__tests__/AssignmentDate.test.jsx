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
import {DateTime} from '@instructure/ui-i18n'
import AssignmentDate from '../AssignmentDate'

const locale = 'en'
const timeZone = DateTime.browserTimeZone()

function renderAssignmentDate(props) {
  return render(
    <AssignmentDate
      mode="view"
      label="Due"
      onChange={() => {}}
      onChangeMode={() => {}}
      onValidate={() => true}
      invalidMessage={() => 'oh no!'}
      value="2108-03-13T15:15:00-07:00"
      {...props}
    />
  )
}

/*
 *  CAUTION: The InstUI DateTimeInput component was deprecated in v7.
 *  Rather than perform the InstUI upgrade for this part of assignments
 *  2, we are just going to short out those components and skip the tests.
 */

describe('AssignmentDate', () => {
  it('renders in view mode', () => {
    const {getByTestId} = renderAssignmentDate()

    expect(getByTestId('AssignmentDate')).toBeInTheDocument()
    expect(getByTestId('EditableDateTime')).toBeInTheDocument()
  })

  it('renders in edit mode', () => {
    const {getByTestId} = renderAssignmentDate({mode: 'edit'})

    expect(getByTestId('AssignmentDate')).toBeInTheDocument()
    expect(getByTestId('EditableDateTime')).toBeInTheDocument()
    expect(getByTestId('EditableDateTime-editor')).toBeInTheDocument()
  })

  it.skip('shows error message with invalid value when in edit mode', () => {
    // because the error message is rendered by the instui DateTimeInput
    const {getAllByText} = renderAssignmentDate({mode: 'edit', onValidate: () => false})

    expect(getAllByText('oh no!')[0]).toBeInTheDocument()
  })

  it('does not show error message in view mode', () => {
    // because the error message is hoisted to the parent OverrideDates
    const {queryByText} = renderAssignmentDate({mode: 'view', onValidate: () => false})

    expect(queryByText('oh no!')).toBeNull()
  })

  it('shows the placeholder when the value is empty', () => {
    const {getByText} = renderAssignmentDate({value: null})

    expect(getByText('No Due Date')).toBeInTheDocument()
  })

  it.skip('handles jibberish date input', () => {
    const value = '2108-03-13T15:15:00-07:00'
    const invalidMessage = jest.fn()
    const {getByDisplayValue} = renderAssignmentDate({
      mode: 'edit',
      onValidate: () => true,
      invalidMessage,
      value,
    })

    const dateDisplay = DateTime.toLocaleString(value, locale, timeZone, 'LL')
    const dinput = getByDisplayValue(dateDisplay)
    dinput.focus()
    fireEvent.change(dinput, {target: {value: 'x'}})
    const timeDisplay = DateTime.toLocaleString(value, locale, timeZone, 'LT')
    const tinput = getByDisplayValue(timeDisplay)
    tinput.focus()

    expect(invalidMessage).toHaveBeenCalled()
  })

  it.skip('handles input', () => {
    function validator(value) {
      const d = new Date(value)
      const reference = new Date('2108-04-13T15:15:00-07:00')
      return d.valueOf() < reference.valueOf()
    }
    const value = '2108-03-13T15:15:00-07:00'
    const invalidMessage = jest.fn()
    const {getByDisplayValue} = renderAssignmentDate({
      mode: 'edit',
      onValidate: validator,
      invalidMessage,
      value,
    })

    const dateDisplay = DateTime.toLocaleString(value, locale, timeZone, 'LL')
    const dinput = getByDisplayValue(dateDisplay)
    dinput.focus()
    fireEvent.change(dinput, {target: {value: '2108-05-13T15:15:00-07:00'}})
    const timeDisplay = DateTime.toLocaleString(value, locale, timeZone, 'LT')
    const tinput = getByDisplayValue(timeDisplay)
    tinput.focus()

    expect(invalidMessage).toHaveBeenCalled()
  })
})
