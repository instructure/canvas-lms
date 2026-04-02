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
import {noop} from 'es-toolkit/compat'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {EnabledState} from '../types'
import * as reduxHooks from 'react-redux'

import PermissionButton from '../PermissionButton'

const PERM_LABEL = 'Add widgets'
const ROLE_LABEL = 'Superuser'

vi.mock('react-redux', () => ({
  useSelector: vi.fn(),
  useDispatch: vi.fn(),
}))

function buildProps({
  enabled = EnabledState.ALL,
  locked = false,
  readonly = false,
  explicit = true,
  applies_to_self,
  applies_to_descendants,
}: {
  enabled?: EnabledState
  locked?: boolean
  readonly?: boolean
  explicit?: boolean
  applies_to_self?: boolean
  applies_to_descendants?: boolean
} = {}) {
  return {
    permission: {enabled, locked, readonly, explicit, applies_to_self, applies_to_descendants},
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
  const mockUseSelector = vi.spyOn(reduxHooks, 'useSelector')
  const mockUseDispatch = vi.spyOn(reduxHooks, 'useDispatch')

  // if anything needs to examine how PermissionButton calls the Redux
  // dispatching methods, this is the way to do it.
  let mockDispatch: any | undefined = undefined

  beforeEach(() => {
    // Reset all redux hook mocks before each test
    mockUseSelector.mockClear()
    mockUseDispatch.mockClear()
    mockDispatch = vi.fn()
    mockUseDispatch.mockReturnValue(mockDispatch)
  })

  it('displays a spinner whilst the API is in flight', () => {
    mockUseSelector
      .mockReturnValueOnce(false) // isSiteAdmin
      .mockReturnValueOnce(true) // apiBusy
      .mockReturnValueOnce(false) // setFocus

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

  describe('applies to self/descendants (site admin)', () => {
    function setupSiteAdmin() {
      mockUseSelector.mockImplementation((selector: any) =>
        selector({
          isSiteAdmin: true,
          apiBusy: [],
          nextFocus: {targetArea: '', roleId: '', permissionName: ''},
        }),
      )
    }

    it('shows "Apply to..." group with both items checked by default', async () => {
      setupSiteAdmin()
      const user = userEvent.setup()
      const props = buildProps({})
      const {container, getByText} = render(<PermissionButton {...props} inTray={true} />)

      const button = container.querySelector('button')!
      await user.click(button)

      expect(getByText('Self')).toBeInTheDocument()
      expect(getByText('Descendants')).toBeInTheDocument()
    })

    it('shows checkmarks even when explicit is false (Use Default)', async () => {
      setupSiteAdmin()
      const user = userEvent.setup()
      const props = buildProps({explicit: false})
      const {container, getByText} = render(<PermissionButton {...props} inTray={true} />)

      const button = container.querySelector('button')!
      await user.click(button)

      // Both "Self" and "Descendants" should be present even with explicit: false
      expect(getByText('Self')).toBeInTheDocument()
      expect(getByText('Descendants')).toBeInTheDocument()
    })

    it('does not show "Apply to..." group for non-site-admins', async () => {
      mockUseSelector.mockReturnValue(false) // isSiteAdmin=false, apiBusy=false, setFocus=false
      const user = userEvent.setup()
      const props = buildProps({})
      const {container, queryByText} = render(<PermissionButton {...props} inTray={true} />)

      const button = container.querySelector('button')!
      await user.click(button)

      expect(queryByText('Self')).toBeNull()
      expect(queryByText('Descendants')).toBeNull()
    })

    it('disables "Apply to..." selections when the permission is disabled', async () => {
      setupSiteAdmin()
      const user = userEvent.setup()
      const props = buildProps({enabled: EnabledState.NONE})
      const {container, getByText} = render(<PermissionButton {...props} inTray={true} />)

      const button = container.querySelector('button')!
      await user.click(button)

      const selfItem = getByText('Self').closest('[role="menuitemcheckbox"]')
      const descendantsItem = getByText('Descendants').closest('[role="menuitemcheckbox"]')
      expect(selfItem).toHaveAttribute('aria-disabled', 'true')
      expect(descendantsItem).toHaveAttribute('aria-disabled', 'true')
    })

    it('dispatches correct action when toggling self off', async () => {
      setupSiteAdmin()
      const user = userEvent.setup()
      const props = buildProps({applies_to_self: true, applies_to_descendants: true})
      const {container, getByText} = render(<PermissionButton {...props} inTray={true} />)

      const button = container.querySelector('button')!
      await user.click(button)

      mockDispatch.mockClear()
      await user.click(getByText('Self'))

      // modifyPermissions returns a thunk, so dispatch is called with a function
      expect(mockDispatch).toHaveBeenCalledWith(expect.any(Function))
    })
  })
})
