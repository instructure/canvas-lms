/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import ActiveDirectoryLookupAttributeSelector from '../components/ActiveDirectoryLookupAttributeSelector'

describe('RemoteLookupFieldSelector', () => {
  const setup = overrides => {
    return render(<ActiveDirectoryLookupAttributeSelector {...overrides} />)
  }

  it('renders without errors', () => {
    const container = setup()

    expect(container.error).toBeFalsy()
  })

  it('calls the passed in callback on input', () => {
    const callbackMock = jest.fn()
    const container = setup({
      fieldChangedHandler: callbackMock,
    })

    fireEvent.click(
      container.getByRole('combobox', {name: /active directory lookup attribute selector/i})
    )
    fireEvent.click(container.getByText(/user principal name \(upn\)/i))

    expect(callbackMock).toHaveBeenCalledTimes(1)
  })

  it('renders the specified lookup field', () => {
    const container = setup({
      selectedLookupField: 'mailNickname',
    })

    expect(
      container.getByRole('combobox', {
        name: /active directory lookup attribute selector/i,
      }).value
    ).toMatch(/email alias \(mailNickname\)/i)
  })
})
