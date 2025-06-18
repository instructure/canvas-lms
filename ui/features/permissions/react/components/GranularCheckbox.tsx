/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {memo, useCallback} from 'react'
import {useSelector, useDispatch} from 'react-redux'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import actions from '../actions'
import type {ReduxState, RolePermission, PermissionModifyAction} from './types'
import {EnabledState} from './types'

const I18n = createI18nScope('permission_button')

interface GranularCheckboxProps {
  roleId: string
  roleLabel: string
  inTray: boolean
  permission: RolePermission
  permissionName: string
  permissionLabel: string
  handleScroll: () => void
}

function GranularCheckbox(props: GranularCheckboxProps): JSX.Element {
  const {roleId, roleLabel, permission, permissionLabel, permissionName, inTray} = props

  const apiBusy = useSelector((s: ReduxState) =>
    s.apiBusy.some(elt => elt.id === roleId && elt.name === permissionName),
  )

  const dispatch = useDispatch()
  const handleClick = useCallback(
    (action: PermissionModifyAction) => dispatch(actions.modifyPermissions(action)),
    [dispatch],
  )

  function toggle() {
    const enabled = permission.enabled === EnabledState.NONE ? true : false
    handleClick({name: permissionName, id: roleId, inTray, enabled, explicit: true})
  }

  const status = permission.enabled === EnabledState.NONE ? I18n.t('Disabled') : I18n.t('Enabled')
  const screenReaderTag = `${status} ${permissionLabel} ${roleLabel}`
  const display = apiBusy ? (
    <Spinner size="x-small" renderTitle={I18n.t('Waiting for request to complete')} />
  ) : (
    <Checkbox
      inline={true}
      checked={permission.enabled !== EnabledState.NONE}
      disabled={permission.readonly}
      label={<ScreenReaderContent>{screenReaderTag}</ScreenReaderContent>}
      onFocus={props.handleScroll}
      onChange={toggle}
      value={permissionLabel}
    />
  )

  return <div className="ic-permissions__permission-button-container">{display}</div>
}

export default memo(GranularCheckbox)
