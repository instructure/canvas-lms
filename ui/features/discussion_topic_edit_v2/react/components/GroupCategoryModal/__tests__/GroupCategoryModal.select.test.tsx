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

import {render, fireEvent} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import React from 'react'
import GroupCategoryModal from '../GroupCategoryModal'

const setup = () => {
  return render(<GroupCategoryModal show={true} onSubmit={vi.fn()} />)
}

describe('GroupCategoryModal > Group Structure select', () => {
  beforeEach(() => {
    // InstUI SimpleSelect reads window.event (IE-era global). Clear it so a
    // stale event from a prior test cannot prevent the dropdown from opening.
    global.event = undefined
    vi.useRealTimers()
  })

  it('enables number input when it picks a group structure', async () => {
    const {getByLabelText, findByLabelText, findByText} = setup()
    const select = getByLabelText('Group Structure')
    fireEvent.click(select)
    fireEvent.click(await findByText('Split students by number of groups', {}, {timeout: 10000}))
    expect(await findByLabelText('Number of Groups', {}, {timeout: 10000})).toBeInTheDocument()
  }, 35000)

  // TODO: InstUI SimpleSelect + NumberInput interaction unreliable in CI
  it.skip('increments/decrements number input, which stays in bounds', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: 0})
    const {getByText, findByText, findByLabelText} = setup()
    await user.click(getByText('Group Structure'))
    await user.click(await findByText('Split students by number of groups', {}, {timeout: 10000}))
    const numberInput = (await findByLabelText(
      'Number of Groups',
      {},
      {timeout: 20000},
    )) as HTMLInputElement
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
  }, 30000)
})
