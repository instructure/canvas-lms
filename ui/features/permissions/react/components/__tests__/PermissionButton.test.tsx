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

import PermissionButton from '../PermissionButton'

const PERM_LABEL = 'Add widgets'
const ROLE_LABEL = 'Superuser'

jest.mock('react-redux', () => ({
  useSelector: jest.fn(),
  useDispatch: jest.fn(),
}))

function buildProps({
  enabled = EnabledState.ALL,
  locked = false,
  readonly = false,
  explicit = true,
}) {
  return {
    permission: {enabled, locked, readonly, explicit},
    permissionName: PERM_LABEL,
    permissionLabel: PERM_LABEL,
    onFocus: noop,
    cleanFocus: noop,
    inTray: false,
    roleId: '1',
    roleLabel: ROLE_LABEL,
  }
}

function getThings(div: HTMLElement) {
  const check = div.querySelector('svg[name="IconPublish"]')
  const x = div.querySelector('svg[name="IconTrouble"]')
  const oval = div.querySelector('svg[name="IconOvalHalf"]')
  const locked = div.querySelector('svg[name="IconLock"]')

  return {check, x, oval, locked}
}

// TODO:  this doesn't test the click/menu actions, just the display!
// Maybe some integration tests do that but it should also be tested here.

describe('permissions::PermissionButton', () => {
  const mockUseSelector = jest.spyOn(reduxHooks, 'useSelector')
  const mockUseDispatch = jest.spyOn(reduxHooks, 'useDispatch')

  // if anything needs to examine how PermissionButton calls the Redux
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
    mockUseSelector
      .mockReturnValueOnce(true) // for apiBusy
      .mockReturnValueOnce(false) // for setFocus

    const {getByText} = render(<PermissionButton {...buildProps({})} />)

    expect(getByText('Waiting for request to complete')).toBeInTheDocument()
  })

  it('displays the enabled state', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container, getByText, queryByText} = render(<PermissionButton {...buildProps({})} />)
    const {check, x, oval, locked} = getThings(container)

    expect(check).not.toBeNull()
    expect(x).toBeNull()
    expect(oval).toBeNull()
    expect(locked).toBeNull()
    expect(getByText(`Enabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
    expect(queryByText('Waiting for request to complete')).toBeNull()
  })

  it('displays the disabled state', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: EnabledState.NONE})} />,
    )
    const {check, x, oval, locked} = getThings(container)

    expect(check).toBeNull()
    expect(x).not.toBeNull()
    expect(oval).toBeNull()
    expect(locked).toBeNull()
    expect(getByText(`Disabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays the partially-enabled state', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: EnabledState.PARTIAL})} />,
    )
    const {check, x, oval, locked} = getThings(container)

    expect(check).toBeNull()
    expect(x).toBeNull()
    expect(oval).not.toBeNull()
    expect(locked).toBeNull()
    expect(getByText(`Partially enabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays enabled and locked', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container, getByText} = render(<PermissionButton {...buildProps({locked: true})} />)
    const {check, x, oval, locked} = getThings(container)

    expect(check).not.toBeNull()
    expect(x).toBeNull()
    expect(oval).toBeNull()
    expect(locked).not.toBeNull()
    expect(getByText(`Enabled and Locked ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays disabled and locked', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: EnabledState.NONE, locked: true})} />,
    )
    const {check, x, oval, locked} = getThings(container)

    expect(check).toBeNull()
    expect(x).not.toBeNull()
    expect(oval).toBeNull()
    expect(locked).not.toBeNull()
    expect(getByText(`Disabled and Locked ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays partially-enabled and locked', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: EnabledState.PARTIAL, locked: true})} />,
    )
    const {check, x, oval, locked} = getThings(container)

    expect(check).toBeNull()
    expect(x).toBeNull()
    expect(oval).not.toBeNull()
    expect(locked).not.toBeNull()
    expect(
      getByText(`Partially enabled and Locked ${PERM_LABEL} ${ROLE_LABEL}`),
    ).toBeInTheDocument()
  })

  it('displays a not-disabled button by default', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container} = render(<PermissionButton {...buildProps({})} />)
    const button = container.querySelector('button')
    expect(button!.disabled).toBeFalsy()
  })

  it('disables the button when permission is readonly', () => {
    mockUseSelector.mockReturnValue(false) // both apiBusy and setFocus

    const {container} = render(<PermissionButton {...buildProps({readonly: true, locked: true})} />)
    const button = container.querySelector('button')
    expect(button!.disabled).toBe(true)
  })
})
