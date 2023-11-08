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

import React from 'react'

import {UsageRights} from '../UsageRights'
import {defaultUsageRights, defaultCreativeOptions} from '../../../util/usageRightsConstants'

const setup = ({onSaveUsageRights = () => {}, isOpen = true, currentUsageRights = {}} = {}) => {
  return render(
    <UsageRights
      onSaveUsageRights={onSaveUsageRights}
      isOpen={isOpen}
      initialUsageRights={currentUsageRights}
      creativeCommonsOptions={defaultCreativeOptions}
      usageRightsOptions={defaultUsageRights}
    />
  )
}

describe('UsageRights', () => {
  it('renders icon', () => {
    const {getAllByText} = setup({isOpen: false})
    expect(getAllByText('Manage Usage Rights')[0]).toBeInTheDocument()
  })

  it('renders modal', () => {
    const {getByText} = setup({isOpen: true})
    expect(getByText('Usage Right:')).toBeInTheDocument()
  })

  it('initializes state from currentUsageRights', () => {
    const currentUsageRights = {
      legalCopyright: 'John Doe',
      useJustification: 'own_copyright',
    }

    const {getByLabelText} = setup({currentUsageRights, isOpen: true})

    expect(getByLabelText('Copyright Holder').value).toBe('John Doe')
    expect(getByLabelText('Usage Right:').value).toBe('I hold the copyright')
  })

  it('reverts to initial state on cancel', () => {
    const {getByText, getByLabelText, getByTestId} = setup({
      currentUsageRights: {
        legalCopyright: '',
      },
      isOpen: true,
    })

    fireEvent.change(getByLabelText('Copyright Holder'), {
      target: {value: 'Jane Smith'},
    })

    fireEvent.click(getByText('Cancel'))

    // re-open the modal
    fireEvent.click(getByTestId('usage-rights-icon'))

    // Check the state has reverted
    expect(getByLabelText('Copyright Holder').value).toBe('')
  })

  it('passes the correct values to onSaveUsageRights', async () => {
    const onSaveUsageRightsMock = jest.fn()
    const {getByText, getByLabelText, findAllByTestId, getByTestId} = setup({
      onSaveUsageRights: onSaveUsageRightsMock,
      isOpen: true,
    })

    const dropdown = getByTestId('usage-select')
    fireEvent.click(dropdown)
    const usageRightsOptions = await findAllByTestId('usage-rights-option')
    fireEvent.click(usageRightsOptions[1])

    fireEvent.change(getByLabelText('Copyright Holder'), {
      target: {value: 'John Doe'},
    })

    fireEvent.click(getByText('Save'))

    expect(onSaveUsageRightsMock).toHaveBeenCalledWith({
      legalCopyright: 'John Doe',
      useJustification: 'own_copyright',
    })
  })
})
