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

import I18n from 'i18n!permissions_v2'

import {connect} from 'react-redux'
import PropTypes from 'prop-types'
import React, {Component} from 'react'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Container from '@instructure/ui-core/lib/components/Container'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-core/lib/components/Heading'
import IconX from '@instructure/ui-icons/lib/Solid/IconX'
import Text from '@instructure/ui-core/lib/components/Text'
import Select from '@instructure/ui-core/lib/components/Select'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Tray from '@instructure/ui-overlays/lib/components/Tray'

import actions from '../actions'
import RoleTrayTable from './RoleTrayTable'
import RoleTrayTableRow from './RoleTrayTableRow'

import {getPermissionsWithLabels, roleIsBaseRole} from '../helper/utils'

const getCurrentPermissions = (displayedPermissions, role) => {
  const permissions = getPermissionsWithLabels(displayedPermissions, role.permissions)
  return {
    assignedPermissions: permissions.filter(p => p.enabled),
    unassignedPermissions: permissions.filter(p => !p.enabled)
  }
}

export default class AddTray extends Component {
  static propTypes = {
    permissions: PropTypes.arrayOf(PropTypes.object).isRequired,
    allBaseRoles: PropTypes.arrayOf(PropTypes.object).isRequired,
    hideTray: PropTypes.func.isRequired,
    open: PropTypes.bool.isRequired
  }

  constructor(props) {
    super(props)
    // This is for the case when the tray is closed
    const currentPermissions = props.allBaseRoles[0]
      ? getCurrentPermissions(props.permissions, props.allBaseRoles[0])
      : {
          assignedPermissions: [],
          unassignedPermissions: []
        }

    this.state = {
      selectedRoleName: '',
      selectedBaseType: this.props.allBaseRoles[0] || {label: ''},
      assignedPermissions: currentPermissions.assignedPermissions,
      unassignedPermissions: currentPermissions.unassignedPermissions
    }
  }

  componentWillReceiveProps(newProps) {
    // This is for the case when the tray is closed
    const currentPermissions = newProps.allBaseRoles[0]
      ? getCurrentPermissions(newProps.permissions, newProps.allBaseRoles[0])
      : {
          assignedPermissions: [],
          unassignedPermissions: []
        }

    this.setState({
      selectedRoleName: '',
      selectedBaseType: newProps.allBaseRoles[0] || {label: ''},
      assignedPermissions: currentPermissions.assignedPermissions,
      unassignedPermissions: currentPermissions.unassignedPermissions
    })
  }

  onChangeRoleName = event => {
    this.setState({selectedRoleName: event.target.value})
  }

  onChangeBaseType = event => {
    const foundRole = this.props.allBaseRoles.find(element => element.label === event.target.value)
    const permissions = getCurrentPermissions(this.props.permissions, foundRole)
    this.setState({
      selectedBaseType: foundRole,
      assignedPermissions: permissions.assignedPermissions,
      unassignedPermissions: permissions.unassignedPermissions
    })
  }

  hideTray = () => {
    this.setState({
      selectedRoleName: '',
      selectedBaseType: this.props.allBaseRoles[0] || {label: ''}
    })
    this.props.hideTray()
  }

  isDoneSelecting = () => !!this.state.selectedRoleName

  renderTrayHeader = () => (
    <Flex alignItems="center" margin="small">
      <FlexItem>
        <Button
          variant="icon"
          size="small"
          onClick={this.hideTray}
          buttonRef={c => (this.closeButton = c)}
        >
          <IconX>Close</IconX>
        </Button>
      </FlexItem>
      <FlexItem>
        <Container as="div" margin="0 0 0 small">
          <Heading level="h3" as="h2">
            {I18n.t('New Course Role')}
          </Heading>
        </Container>
      </FlexItem>
    </Flex>
  )

  renderPermissions = () => (
    <div>
      {this.state.assignedPermissions.length !== 0 && (
        <RoleTrayTable title="Assigned Permissions">
          {this.state.assignedPermissions.map(perm => (
            <RoleTrayTableRow title={perm.label} description="" expandable={false} />
          ))}
        </RoleTrayTable>
      )}

      {this.state.unassignedPermissions.length !== 0 && (
        <RoleTrayTable title="Unassigned Permissions">
          {this.state.unassignedPermissions.map(perm => (
            <RoleTrayTableRow title={perm.label} description="" expandable={false} />
          ))}
        </RoleTrayTable>
      )}
    </div>
  )

  renderSelectRoleName = () => (
    <Container display="block" margin="medium 0">
      <TextInput
        onChange={this.onChangeRoleName}
        value={this.state.selectedRoleName}
        label={<Text weight="light">{`${I18n.t('Role Name')}:`}</Text>}
      />
    </Container>
  )

  renderSelectBaseRole = () => (
    <Container display="block" margin="medium 0">
      <Select
        onChange={this.onChangeBaseType}
        value={this.state.selectedBaseType.label}
        label={<Text weight="light">{`${I18n.t('Base Type')}:`}</Text>}
      >
        {this.props.allBaseRoles.map(item => (
          <option key={item.label} value={item.label}>
            {item.label}
          </option>
        ))}
      </Select>
    </Container>
  )

  renderTrayFooter() {
    return (
      <div className="permissions__add-tray-footer">
        <Container textAlign="end" display="block">
          <hr />
          <Button
            id="permissions-add-tray-cancel-button"
            onClick={this.props.hideTray}
            margin="0 x-small 0 0"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            id="permissions-add-tray-submit-button"
            disabled={!this.isDoneSelecting()}
            type="submit"
            variant="primary"
            onClick={this.submitSelection}
            margin="0 x-small 0 0"
          >
            {I18n.t('Save')}
          </Button>
        </Container>
      </div>
    )
  }

  render() {
    return (
      <Tray
        label={I18n.t('New Course Role')}
        open={this.props.open}
        onDismiss={this.hideTray}
        size="small"
        placement="end"
      >
        {this.renderTrayHeader()}
        <Container as="div" padding="small small x-large small">
          {this.renderSelectRoleName()}
          {this.renderSelectBaseRole()}
          {this.renderPermissions()}
        </Container>
        {this.renderTrayFooter()}
      </Tray>
    )
  }
}

function mapStateToProps(state, ownProps) {
  if (!state.activeAddTray) {
    const stateProps = {
      allBaseRoles: [],
      open: false,
      permissions: []
    }
    return {...stateProps, ...ownProps}
  }

  const allBaseRoles = state.roles.reduce((acc, r) => {
    if (roleIsBaseRole(r)) {
      acc.push(r)
    }
    return acc
  }, [])

  const stateProps = {
    allBaseRoles,
    open: true,
    permissions: state.permissions
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  hideTray: actions.hideAllTrays
}

export const ConnectedAddTray = connect(mapStateToProps, mapDispatchToProps)(AddTray)
