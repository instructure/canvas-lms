/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {noop} from 'lodash'
import {render} from '@testing-library/react'
import {EnabledState} from '../types'
import * as reduxHooks from 'react-redux'

import GranularCheckbox from '../GranularCheckbox'

const ROLE_LABEL = 'Superuser'
const PERM_LABEL = 'Add widgets'

jest.mock('react-redux', () => ({
  useSelector: jest.fn(),
  useDispatch: jest.fn(),
}))

function buildProps({enabled = EnabledState.ALL, readonly = false}) {
  return {
    permission: {enabled, readonly, locked: false, explicit: true},
    permissionName: PERM_LABEL,
    permissionLabel: PERM_LABEL,
    roleLabel: ROLE_LABEL,
    roleId: '1',
    inTray: false,
    handleScroll: noop,
    handleClick: noop,
    apiBusy: false,
  }
}

describe('permissions::GranularCheckbox', () => {
  const mockUseSelector = jest.spyOn(reduxHooks, 'useSelector')
  const mockUseDispatch = jest.spyOn(reduxHooks, 'useDispatch')

  // if anything needs to examine how GranularCheckbox calls the Redux
  // dispatching methods, this is the way to do it.
  let mockDispatch: jest.Mock | undefined = undefined

  beforeEach(() => {
    // Reset all redux hook mocks before each test
    mockUseSelector.mockClear()
    mockUseDispatch.mockClear()
    mockDispatch = jest.fn()
    mockUseDispatch.mockReturnValue(mockDispatch)
  })

  it('displays a spinner whilst the API is in flight', () => {
    mockUseSelector.mockReturnValue(true) // apiBusy
    const {getByText} = render(<GranularCheckbox {...buildProps({})} />)

    expect(getByText('Waiting for request to complete')).toBeInTheDocument()
  })

  it('displays the enabled state', () => {
    mockUseSelector.mockReturnValue(false) // apiBusy

    const {container, getByText, queryByText} = render(<GranularCheckbox {...buildProps({})} />)
    const checkbox = container.querySelector('input')

    expect(getByText(`Enabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
    expect(queryByText('Waiting for request to complete')).toBeNull()
    expect(checkbox).toBeChecked()
    expect(checkbox).toBeEnabled()
  })

  it('displays the disabled state', () => {
    mockUseSelector.mockReturnValue(false) // apiBusy

    const {container, getByText, queryByText} = render(
      <GranularCheckbox {...buildProps({enabled: EnabledState.NONE})} />,
    )
    const checkbox = container.querySelector('input')

    expect(getByText(`Disabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
    expect(queryByText('Waiting for request to complete')).toBeNull()
    expect(checkbox).not.toBeChecked()
    expect(checkbox).toBeEnabled()
  })

  it('displays the readonly state', () => {
    mockUseSelector.mockReturnValue(false) // apiBusy

    const {container, getByText, queryByText} = render(
      <GranularCheckbox {...buildProps({readonly: true})} />,
    )
    const checkbox = container.querySelector('input')

    expect(getByText(`Enabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
    expect(queryByText('Waiting for request to complete')).toBeNull()
    expect(checkbox).toBeChecked()
    expect(checkbox).toBeDisabled()
  })
})
