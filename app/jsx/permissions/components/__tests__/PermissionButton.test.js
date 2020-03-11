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
import {ENABLED_FOR_NONE, ENABLED_FOR_ALL, ENABLED_FOR_PARTIAL} from '../../propTypes'

import PermissionButton from '../PermissionButton'

const PERM_LABEL = 'Add widgets'
const ROLE_LABEL = 'Superuser'

function buildProps({
  enabled = ENABLED_FOR_ALL,
  locked = false,
  readonly = false,
  explicit = true
}) {
  return {
    permission: {enabled, locked, readonly, explicit},
    permissionName: PERM_LABEL,
    permissionLabel: PERM_LABEL,
    onFocus: noop,
    cleanFocus: noop,
    inTray: false,
    setFocus: false,
    roleId: '1',
    roleLabel: ROLE_LABEL,
    fixButtonFocus: noop,
    handleClick: noop
  }
}

describe('permissions::PermissionButton', () => {
  function getThings(div) {
    const check = div.querySelector('svg[name="IconPublish"]')
    const x = div.querySelector('svg[name="IconTrouble"]')
    const oval = div.querySelector('svg[name="IconOvalHalf"]')
    const hideLock = div.querySelector('.ic-hidden-button')

    return {check, x, oval, hideLock}
  }

  it('displays the enabled state', () => {
    const {container, getByText} = render(<PermissionButton {...buildProps({})} />)
    const {check, x, oval, hideLock} = getThings(container)

    expect(check).not.toBeNull()
    expect(x).toBeNull()
    expect(oval).toBeNull()
    expect(hideLock).not.toBeNull()
    expect(getByText(`Enabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays the disabled state', () => {
    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: ENABLED_FOR_NONE})} />
    )
    const {check, x, oval, hideLock} = getThings(container)

    expect(check).toBeNull()
    expect(x).not.toBeNull()
    expect(oval).toBeNull()
    expect(hideLock).not.toBeNull()
    expect(getByText(`Disabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays the partially-enabled state', () => {
    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: ENABLED_FOR_PARTIAL})} />
    )
    const {check, x, oval, hideLock} = getThings(container)

    expect(check).toBeNull()
    expect(x).toBeNull()
    expect(oval).not.toBeNull()
    expect(hideLock).not.toBeNull()
    expect(getByText(`Partially enabled ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays enabled and locked', () => {
    const {container, getByText} = render(<PermissionButton {...buildProps({locked: true})} />)
    const {check, x, oval, hideLock} = getThings(container)

    expect(check).not.toBeNull()
    expect(x).toBeNull()
    expect(oval).toBeNull()
    expect(hideLock).toBeNull()
    expect(getByText(`Enabled and Locked ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays disabled and locked', () => {
    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: ENABLED_FOR_NONE, locked: true})} />
    )
    const {check, x, oval, hideLock} = getThings(container)

    expect(check).toBeNull()
    expect(x).not.toBeNull()
    expect(oval).toBeNull()
    expect(hideLock).toBeNull()
    expect(getByText(`Disabled and Locked ${PERM_LABEL} ${ROLE_LABEL}`)).toBeInTheDocument()
  })

  it('displays partially-enabled and locked', () => {
    const {container, getByText} = render(
      <PermissionButton {...buildProps({enabled: ENABLED_FOR_PARTIAL, locked: true})} />
    )
    const {check, x, oval, hideLock} = getThings(container)

    expect(check).toBeNull()
    expect(x).toBeNull()
    expect(oval).not.toBeNull()
    expect(hideLock).toBeNull()
    expect(
      getByText(`Partially enabled and Locked ${PERM_LABEL} ${ROLE_LABEL}`)
    ).toBeInTheDocument()
  })

  it('displays a not-disabled button by default', () => {
    const {container} = render(<PermissionButton {...buildProps({})} />)
    const button = container.querySelector('button')
    expect(button.disabled).toBeFalsy()
  })

  it('disables the button when permission is readonly', () => {
    const {container} = render(<PermissionButton {...buildProps({readonly: true, locked: true})} />)
    const button = container.querySelector('button')
    expect(button.disabled).toBe(true)
  })
})
