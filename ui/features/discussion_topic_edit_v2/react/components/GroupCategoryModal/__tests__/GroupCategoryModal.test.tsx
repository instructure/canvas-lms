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

const setup = (onSubmit = vi.fn()) => {
  return render(<GroupCategoryModal show={true} onSubmit={onSubmit} />)
}

describe('GroupCategoryModal', () => {
  it('renders', () => {
    const {getByText} = setup()
    expect(getByText('Group Set Name')).toBeInTheDocument()
  })

  it('opens Leadership section when it clicks allows checkbox', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: 0})
    const {queryByText, getAllByText, getByText} = setup()
    expect(queryByText('Leadership')).not.toBeInTheDocument()
    await user.click(getByText('Allow'))
    expect(getAllByText('Leadership')[0]).toBeInTheDocument()
  })

  it('unchecks suboordinate options when it unchecks allow checkbox', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: 0})
    const {getByText} = setup()
    await user.click(getByText('Allow'))
    getByText('Require group members to be in the same section').click()
    await user.click(getByText('Allow'))
    expect(getByText('Require group members to be in the same section')).not.toBeChecked()
  })

  it('clears correct shown/hidden options when it unchecks allow checkbox', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: 0})
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

  it('calls submission function on submit', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: 0})
    const onSubmit = vi.fn()
    const {getByText} = setup(onSubmit)
    await user.click(getByText('Submit'))
    expect(onSubmit).toHaveBeenCalled()
  })
})
