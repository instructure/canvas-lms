/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {InternalSettingActionButtons} from '../../table/InternalSettingActionButtons'
import React from 'react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'

const onSubmitChanges = jest.fn()
const onClearChanges = jest.fn()
const onDelete = jest.fn()

describe('InternalSettingActionButtons', () => {
  it('only shows save and reset buttons with a pending change', () => {
    const {getByText, queryByText} = render(
      <InternalSettingActionButtons
        name="my_setting"
        onSubmitPendingChange={onSubmitChanges}
        onClearPendingChange={onClearChanges}
        onDelete={onDelete}
        pendingChange={true}
      />
    )

    expect(queryByText('Delete "my_setting"')).not.toBeInTheDocument()
    expect(getByText('Save "my_setting"')).toBeInTheDocument()
    expect(getByText('Reset "my_setting"')).toBeInTheDocument()
  })

  it('only shows delete button without a pending change', () => {
    const {getByText, queryByText} = render(
      <InternalSettingActionButtons
        name="my_setting"
        onSubmitPendingChange={onSubmitChanges}
        onClearPendingChange={onClearChanges}
        onDelete={onDelete}
      />
    )

    expect(queryByText('Save "my_setting"')).not.toBeInTheDocument()
    expect(queryByText('Reset "my_setting"')).not.toBeInTheDocument()
    expect(getByText('Delete "my_setting"')).toBeInTheDocument()
  })

  it('buttons call the appropriate callbacks', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    const {getByText, rerender} = render(
      <InternalSettingActionButtons
        name="my_setting"
        onSubmitPendingChange={onSubmitChanges}
        onClearPendingChange={onClearChanges}
        onDelete={onDelete}
      />
    )

    await user.click(getByText('Delete "my_setting"'))
    expect(onDelete).toHaveBeenCalled()

    rerender(
      <InternalSettingActionButtons
        name="my_setting"
        onSubmitPendingChange={onSubmitChanges}
        onClearPendingChange={onClearChanges}
        onDelete={onDelete}
        pendingChange={true}
      />
    )

    await user.click(getByText('Save "my_setting"'))
    expect(onSubmitChanges).toHaveBeenCalled()

    await user.click(getByText('Reset "my_setting"'))
    expect(onClearChanges).toHaveBeenCalled()
  })

  it('displays only a tooltip and no buttons when the setting is secret', async () => {
    const {container, queryByText, getByText} = render(
      <InternalSettingActionButtons
        name="my_setting"
        onSubmitPendingChange={onSubmitChanges}
        onClearPendingChange={onClearChanges}
        onDelete={onDelete}
        secret={true}
      />
    )

    expect(queryByText('Delete "my_setting"')).not.toBeInTheDocument()

    await userEvent.hover(container)

    expect(
      getByText('This is a secret setting, and may only be modified from the console')
    ).toBeInTheDocument()
  })
})
