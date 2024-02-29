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
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import React from 'react'
import GroupCategoryModal from '../GroupCategoryModal'

const setup = (onSubmit = jest.fn()) => {
  return render(<GroupCategoryModal show={true} onSubmit={onSubmit} />)
}

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null}

describe('GroupCategoryModal', () => {
  it('renders', () => {
    const {getByText} = setup()
    expect(getByText('Group Set Name')).toBeInTheDocument()
  })
  it('opens Leadership section when it clicks allows checkbox', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {queryByText, getAllByText, getByText} = setup()
    expect(queryByText('Leadership', {hidden: false})).not.toBeInTheDocument()
    await user.click(getByText('Allow'))
    expect(getAllByText('Leadership', {hidden: false})[0]).toBeInTheDocument()
  })

  it('unchecks suboordinate options when it unchecks allow checkbox', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText} = setup()
    await user.click(getByText('Allow'))
    getByText('Require group members to be in the same section').click()
    await user.click(getByText('Allow'))
    expect(getByText('Require group members to be in the same section')).not.toBeChecked()
  })

  it('clears correct shown/hidden options when it unchecks allow checkbox', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText} = setup()
    const allowCheckbox = getByText('Allow')
    await user.click(allowCheckbox)
    getByText('Automatically assign a student group leader').click()
    getByText('Set first student to join as group leader').click()
    await user.click(allowCheckbox)
    await user.click(allowCheckbox)
    expect(getByText('Automatically assign a student group leader')).not.toBeChecked()
    expect(getByText('Set first student to join as group leader')).not.toBeChecked()
  })

  it('enables number input when it picks a group structure', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, findByLabelText} = setup()
    await user.click(getByText('Group Structure'))
    await user.click(getByText('Split students by number of groups'))
    expect(await findByLabelText('Number of Groups')).toBeInTheDocument()
  })

  it('increments/decrements number input, which stays in bounds', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {getByText, getByLabelText} = setup()
    await user.click(getByText('Group Structure'))
    await user.click(getByText('Split students by number of groups'))
    const numberInput = getByLabelText('Number of Groups')
    await user.type(numberInput, '{arrowdown}')
    expect(numberInput.value).toBe('0')
    // userEvent's {arrowup} does not work with number inputs
    // https://github.com/testing-library/user-event/issues/1066
    // await user.type(numberInput, '{arrowup}{arrowup}')
    await user.type(numberInput, '2')
    expect(numberInput.value).toBe('2')
    // bigger than the default maximum (200)
    await user.type(numberInput, '99999999999999999')
    expect(numberInput.value).toBe('200')
  })

  it('calls submission function on submit', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const onSubmit = jest.fn()
    const {getByText} = setup(onSubmit)
    await user.click(getByText('Submit'))
    expect(onSubmit).toHaveBeenCalled()
  })
})
