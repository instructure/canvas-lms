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

import React from 'react'
import {func, bool, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {connect} from 'react-redux'
import {Checkbox} from '@instructure/ui-checkbox'
import {Spinner} from '@instructure/ui-spinner'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import actions from '../actions'
import propTypes, {ENABLED_FOR_NONE} from '@canvas/permissions/react/propTypes'

const I18n = useI18nScope('permission_button')

export default function GranularCheckbox({
  apiBusy,
  roleId,
  roleLabel,
  permission,
  permissionName,
  permissionLabel,
  handleClick,
  handleScroll,
}) {
  const status = permission.enabled === ENABLED_FOR_NONE ? I18n.t('Disabled') : I18n.t('Enabled')
  const screenReaderTag = `${status} ${permissionLabel} ${roleLabel}`
  const display = apiBusy ? (
    <Spinner size="x-small" renderTitle={I18n.t('Waiting for request to complete')} />
  ) : (
    <Checkbox
      inline={true}
      checked={permission.enabled !== ENABLED_FOR_NONE}
      disabled={permission.readonly}
      label={<ScreenReaderContent>{screenReaderTag}</ScreenReaderContent>}
      onFocus={handleScroll}
      onChange={toggle.bind(this)}
      value={permissionLabel}
    />
  )

  function toggle() {
    const enabled = !permission.enabled

    handleClick({enabled, explicit: true, id: roleId, name: permissionName})
  }

  return <div className="ic-permissions__permission-button-container">{display}</div>
}

GranularCheckbox.propTypes = {
  apiBusy: bool.isRequired,
  roleId: string.isRequired,
  roleLabel: string,
  permission: propTypes.rolePermission.isRequired,
  permissionName: string.isRequired,
  permissionLabel: string.isRequired,
  handleClick: func.isRequired,
  handleScroll: func,
}

GranularCheckbox.defaultProps = {
  roleLabel: '',
  handleScroll: Function.prototype,
}

function mapStateToProps(state, ownProps) {
  const apiBusy = state.apiBusy.some(
    elt => elt.id === ownProps.roleId && elt.name === ownProps.permissionName
  )

  return {apiBusy, ...ownProps}
}

const mapDispatchToProps = {
  handleClick: actions.modifyPermissions,
}

export const ConnectedGranularCheckbox = connect(
  mapStateToProps,
  mapDispatchToProps
)(GranularCheckbox)
