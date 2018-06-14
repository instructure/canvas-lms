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
import I18n from 'i18n!permissions_role_tray'
import {connect} from 'react-redux'
import PropTypes from 'prop-types'
import React from 'react'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Container from '@instructure/ui-layout/lib/components/View'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import IconX from '@instructure/ui-icons/lib/Solid/IconX'
import Tray from '@instructure/ui-overlays/lib/components/Tray'

import actions from '../actions'
import RoleTrayTable from './RoleTrayTable'
import RoleTrayTableRow from './RoleTrayTableRow'
import permissionPropTypes from '../propTypes'

// TODO don't pass in label if we are passing in permission
export default function PermissionTray(props) {
  return (
    <Tray
      label={props.label}
      open={props.open}
      onDismiss={props.hideTray}
      size="small"
      placement="end"
    >
      <Button variant="icon" size="small" margin="small 0 0 xx-small" onClick={props.hideTray}>
        <IconX title={I18n.t('Close')} />
      </Button>

      <Container as="div" padding="small small x-large small">
        <Heading level="h3" as="h2" margin="0 0 medium 0">
          {props.label}
        </Heading>

        {props.assignedRoles.length !== 0 && (
          <RoleTrayTable title={I18n.t('Assigned Roles')}>
            {props.assignedRoles.map(role => (
              <RoleTrayTableRow
                key={role.label}
                title={role.label}
                description=""
                expandable={false}
                permissionName={props.permissionName}
                permission={role.permissions[props.permissionName]}
                role={role}
                useCaching={props.useCaching}
              />
            ))}
          </RoleTrayTable>
        )}

        {props.unassignedRoles.length !== 0 && (
          <RoleTrayTable title={I18n.t('Unassigned Roles')}>
            {props.unassignedRoles.map(role => (
              <RoleTrayTableRow
                key={role.label}
                title={role.label}
                description=""
                expandable={false}
                permissionName={props.permissionName}
                permission={role.permissions[props.permissionName]}
                role={role}
                useCaching={props.useCaching}
              />
            ))}
          </RoleTrayTable>
        )}
      </Container>
    </Tray>
  )
}

PermissionTray.propTypes = {
  assignedRoles: PropTypes.arrayOf(permissionPropTypes.role).isRequired,
  hideTray: PropTypes.func.isRequired,
  label: PropTypes.string.isRequired,
  open: PropTypes.bool.isRequired,
  unassignedRoles: PropTypes.arrayOf(permissionPropTypes.role).isRequired,
  permissionName: PropTypes.string.isRequired,
  useCaching: PropTypes.bool
}

PermissionTray.defaultProps = {
  useCaching: true
}

function mapStateToProps(state, ownProps) {
  if (state.activePermissionTray === null) {
    const stateProps = {
      assignedRoles: [],
      label: '',
      open: false,
      unassignedRoles: []
    }
    return {...stateProps, ...ownProps}
  }

  const permission = state.permissions.find(
    p => p.permission_name === state.activePermissionTray.permissionName
  )
  const permissionName = permission.permission_name
  const displayedRoles = state.roles.filter(r => r.displayed)

  const stateProps = {
    assignedRoles: displayedRoles.filter(r => r.permissions[permissionName].enabled),
    permissionName,
    label: permission.label,
    open: true,
    unassignedRoles: displayedRoles.filter(r => !r.permissions[permissionName].enabled)
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  hideTray: actions.hideAllTrays
}

export const ConnectedPermissionTray = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionTray)
