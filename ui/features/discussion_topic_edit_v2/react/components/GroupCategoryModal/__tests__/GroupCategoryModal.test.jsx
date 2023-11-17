// @vitest-environment jsdom
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import GroupCategoryModal from '../GroupCategoryModal'

const setup = (onSubmit = jest.fn()) => {
  return render(<GroupCategoryModal show={true} onSubmit={onSubmit} />)
}

describe('GroupCategoryModal', () => {
  it('renders', () => {
    const {getByText} = setup()
    expect(getByText('Group Set Name')).toBeInTheDocument()
  })
  it('opens Leadership section when it clicks allows checkbox', () => {
    const {queryByText, getAllByText, getByText} = setup()
    expect(queryByText('Leadership', {hidden: false})).not.toBeInTheDocument()
    getByText('Allow').click()
    expect(getAllByText('Leadership', {hidden: false})[0]).toBeInTheDocument()
  })

  it('unchecks suboordinate options when it unchecks allow checkbox', () => {
    const {getByText} = setup()
    getByText('Allow').click()
    getByText('Require group members to be in the same section').click()
    getByText('Allow').click()
    expect(getByText('Require group members to be in the same section')).not.toBeChecked()
  })

  it('clears correct shown/hidden options when it unchecks allow checkbox', () => {
    const {getByText} = setup()
    const allowCheckbox = getByText('Allow')
    allowCheckbox.click()
    getByText('Automatically assign a student group leader').click()
    getByText('Set first student to join as group leader').click()
    allowCheckbox.click()
    allowCheckbox.click()
    expect(getByText('Automatically assign a student group leader')).not.toBeChecked()
    expect(getByText('Set first student to join as group leader')).not.toBeChecked()
  })

  it('enables number input when it picks a group structure', () => {
    const {getByText, getByLabelText} = setup()
    userEvent.click(getByText('Group Structure'))
    userEvent.click(getByText('Split students by number of groups'))
    expect(getByLabelText('Number of Groups')).toBeInTheDocument()
  })

  it('increments/decrements number input, which stays in bounds', () => {
    const {getByText, getByLabelText} = setup()
    userEvent.click(getByText('Group Structure'))
    userEvent.click(getByText('Split students by number of groups'))
    const numberInput = getByLabelText('Number of Groups')
    userEvent.type(numberInput, '{arrowdown}')
    expect(numberInput.value).toBe('0')
    userEvent.type(numberInput, '{arrowup}{arrowup}')
    expect(numberInput.value).toBe('2')
    // bigger than the default maximum (200)
    userEvent.type(numberInput, '99999999999999999')
    expect(numberInput.value).toBe('200')
  })

  it('calls submission function on submit', () => {
    const onSubmit = jest.fn()
    const {getByText} = setup(onSubmit)
    getByText('Submit').click()
    expect(onSubmit).toHaveBeenCalled()
  })
})
