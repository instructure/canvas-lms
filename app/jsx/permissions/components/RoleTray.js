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
import React, {Component} from 'react'

import Alert from '@instructure/ui-alerts/lib/components/Alert'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Container from '@instructure/ui-core/lib/components/Container'
import Dialog from '@instructure/ui-a11y/lib/components/Dialog'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-core/lib/components/Heading'
import IconArrowStart from '@instructure/ui-icons/lib/Solid/IconArrowStart'
import IconEdit from '@instructure/ui-icons/lib/Line/IconEdit'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import IconX from '@instructure/ui-icons/lib/Solid/IconX'
import Select from '@instructure/ui-forms/lib/components/Select'
import Text from '@instructure/ui-core/lib/components/Text'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Tray from '@instructure/ui-overlays/lib/components/Tray'

import actions from '../actions'
import RoleTrayTable from './RoleTrayTable'
import RoleTrayTableRow from './RoleTrayTableRow'
import permissionPropTypes from '../propTypes'

import {getPermissionsWithLabels, roleIsBaseRole} from '../helper/utils'

export default class RoleTray extends Component {
  static propTypes = {
    assignedPermissions: PropTypes.arrayOf(permissionPropTypes.permission).isRequired,
    assignedTo: PropTypes.string.isRequired,
    basedOn: PropTypes.string,
    baseRoleLabels: PropTypes.arrayOf(PropTypes.string),
    changedBy: PropTypes.string.isRequired,
    deletable: PropTypes.bool.isRequired,
    editable: PropTypes.bool.isRequired,
    hideTray: PropTypes.func.isRequired,
    label: PropTypes.string.isRequired,
    lastChanged: PropTypes.string.isRequired,
    open: PropTypes.bool.isRequired,
    unassignedPermissions: PropTypes.arrayOf(permissionPropTypes.permission).isRequired
  }

  static defaultProps = {
    basedOn: null,
    baseRoleLabels: []
  }

  state = {
    deleteAlertVisable: false,
    editBaseRoleAlertVisable: false,
    editTrayVisable: false
  }

  // We need this so that if there is an alert displayed inside this tray
  // (such as the delete confirmation alert) it will disapear if we click
  // on a different role then we are currently operating on.
  componentWillReceiveProps() {
    this.setState({
      deleteAlertVisable: false,
      editTrayVisable: false,
      editBaseRoleAlertVisable: false
    })
  }

  hideTray = () => {
    this.props.hideTray()
    this.setState({
      deleteAlertVisable: false,
      editTrayVisable: false,
      editBaseRoleAlertVisable: false
    })
  }

  showEditTray = () => {
    this.setState(
      {
        deleteAlertVisable: false,
        editTrayVisable: true,
        editBaseRoleAlertVisable: false
      },
      () => this.closeButton.focus()
    )
  }

  hideEditTray = () => {
    this.setState(
      {
        deleteAlertVisable: false,
        editTrayVisable: false,
        editBaseRoleAlertVisable: false
      },
      () => this.editButton.focus()
    )
  }

  showDeleteAlert = () => {
    this.setState({
      deleteAlertVisable: true,
      editTrayVisable: false,
      editBaseRoleAlertVisable: false
    })
  }

  hideDeleteAlert = () => {
    this.setState(
      {
        deleteAlertVisable: false,
        editTrayVisable: false,
        editBaseRoleAlertVisable: false
      },
      () => this.deleteButton.focus()
    )
  }

  showEditBaseRoleAlert = () => {
    this.setState({
      deleteAlertVisable: false,
      editTrayVisable: true,
      editBaseRoleAlertVisable: true
    })
  }

  hideEditBaseRoleAlert = () => {
    this.setState(
      {
        deleteAlertVisable: false,
        editTrayVisable: true,
        editBaseRoleAlertVisable: false
      },
      () => this.editRoleInput.focus()
    )
  }

  // TODO maybe make this a whole other component we can use/reuse?
  renderConfirmationAlert = (children, onOk, onCancel) => (
    <div style={{zIndex: 10, position: 'absolute'}}>
      <Dialog open shouldContainFocus>
        <Alert variant="warning" margin="small">
          <Container as="block">
            {children}
            <Container as="block" margin="small 0 0 0">
              <Button onClick={onOk} margin="none xx-small none none">
                {I18n.t('Cancel')}
              </Button>
              <Button onClick={onCancel} variant="primary">
                {I18n.t('Ok')}
              </Button>
            </Container>
          </Container>
        </Alert>
      </Dialog>
    </div>
  )

  renderDeleteAlert = () => {
    const text = (
      <div className="role-tray-delete-alert-confirm">
        <Text as="p">
          {I18n.t(
            'Warning: If there are any users with this role, they will keep ' +
              'the current permissions but you will not be able to create new ' +
              'users with this role.'
          )}
        </Text>
        <Text as="p">{I18n.t('Click "ok" to continue deleting this role.')}</Text>
      </div>
    )
    return this.renderConfirmationAlert(text, this.hideDeleteAlert, this.hideTray)
  }

  renderEditBaseRoleAlert = () => {
    const text = (
      <div className="role-tray-edit-base-role-confirm">
        <Text as="p">
          {I18n.t('Warning: All permissions will change to match the selected base role.')}
        </Text>
      </div>
    )
    return this.renderConfirmationAlert(
      text,
      this.hideEditBaseRoleAlert,
      this.hideEditBaseRoleAlert
    )
  }

  renderCloseButton = () => (
    <Button
      variant="icon"
      size="small"
      margin="small 0 0 xx-small"
      onClick={this.state.editTrayVisable ? this.hideEditTray : this.hideTray}
      buttonRef={c => (this.closeButton = c)}
    >
      {this.state.editTrayVisable ? (
        <IconArrowStart title={I18n.t('Back')} />
      ) : (
        <IconX title={I18n.t('Close')} />
      )}
    </Button>
  )

  renderPermissions = () => (
    <div>
      {this.props.assignedPermissions.length !== 0 && (
        <RoleTrayTable title={I18n.t('Assigned Permissions')}>
          {this.props.assignedPermissions.map(perm => (
            <RoleTrayTableRow
              key={perm.label}
              title={perm.label}
              description=""
              expandable={false}
            />
          ))}
        </RoleTrayTable>
      )}

      {this.props.unassignedPermissions.length !== 0 && (
        <RoleTrayTable title={I18n.t('Unassigned Permissions')}>
          {this.props.unassignedPermissions.map(perm => (
            <RoleTrayTableRow
              key={perm.label}
              title={perm.label}
              description=""
              expandable={false}
            />
          ))}
        </RoleTrayTable>
      )}
    </div>
  )

  renderEditButton = () => (
    <Button
      variant="icon"
      size="medium"
      onClick={this.showEditTray}
      buttonRef={c => (this.editButton = c)}
    >
      <Text color="brand">
        <IconEdit title={I18n.t('Edit')} />
      </Text>
    </Button>
  )

  renderDeleteButton = () => (
    <Button
      variant="icon"
      size="medium"
      onClick={this.showDeleteAlert}
      buttonRef={c => (this.deleteButton = c)}
    >
      <Text color="brand">
        <IconTrash title={I18n.t('Delete')} />
      </Text>
    </Button>
  )

  renderTrayHeader = () => (
    <div>
      <Flex alignItems="start" justifyItems="space-between">
        <FlexItem>
          <Container as="div">
            <Heading level="h3" as="h2">
              {this.props.label}
            </Heading>
            {this.props.basedOn && (
              <Text size="small" className="role-tray-based-on">
                {I18n.t('Based on: %{basedOn}', {basedOn: this.props.basedOn})}
              </Text>
            )}
          </Container>
        </FlexItem>
        <FlexItem>
          {this.props.editable && this.renderEditButton()}
          {this.props.deletable && this.renderDeleteButton()}
        </FlexItem>
      </Flex>

      <Container as="div" margin="small 0 medium 0">
        <Flex direction="column">
          <FlexItem>
            <Text className="role-tray-assigned-to">
              {I18n.t('Assigned to: %{count}', {count: this.props.assignedTo})}
            </Text>
          </FlexItem>
          <FlexItem>
            <Text className="role-tray-last-changed">
              {I18n.t('Last changed: %{date}', {date: this.props.lastChanged})}
            </Text>
          </FlexItem>
          <FlexItem>
            <Text className="role-tray-changed-by">
              {I18n.t('Changed by: %{person}', {person: this.props.changedBy})}
            </Text>
          </FlexItem>
        </Flex>
      </Container>
    </div>
  )

  renderEditHeader = () => (
    <div>
      <Heading level="h3" as="h2">
        {I18n.t('Edit %{label}', {label: this.props.label})}
      </Heading>

      <Container as="div" margin="medium 0 small 0">
        <TextInput
          label={I18n.t('Role Name')}
          defaultValue={this.props.label}
          onBlur={() => console.log('todo actually save this to backend here')}
        />
      </Container>

      <Container as="div" margin="medium 0 large 0">
        <Select
          label={I18n.t('Base Type')}
          defaultOption={this.props.basedOn}
          onChange={(_event, _option) => this.showEditBaseRoleAlert()}
          inputRef={c => (this.editRoleInput = c)}
        >
          {this.props.baseRoleLabels.map(label => (
            <option key={label} value={label}>
              {label}
            </option>
          ))}
        </Select>
      </Container>
    </div>
  )

  render() {
    return (
      <Tray
        label={this.props.label}
        open={this.props.open}
        onDismiss={this.hideTray}
        size="small"
        placement="end"
      >
        {/* TODO Once INSTUI-1269 is fixed and in canvas, use shouldReturnFocus
                 open, and defaultFocusElement dialog props instead of the &&
                 we are currently using to complete destroy this component */}
        {this.state.deleteAlertVisable && this.renderDeleteAlert()}
        {this.state.editBaseRoleAlertVisable && this.renderEditBaseRoleAlert()}
        {this.renderCloseButton()}
        <Container as="div" padding="small small x-large small">
          {this.state.editTrayVisable ? this.renderEditHeader() : this.renderTrayHeader()}
          {this.renderPermissions()}
        </Container>
      </Tray>
    )
  }
}

function getBaseRoleLabel(role, state) {
  return state.roles.find(ele => ele.role === role.base_role_type).label
}

function mapStateToProps(state, ownProps) {
  if (state.activeRoleTray === null) {
    const stateProps = {
      assignedTo: '',
      basedOn: null,
      changedBy: '',
      deletable: false,
      editable: false,
      label: '',
      lastChanged: '',
      open: false,
      assignedPermissions: [],
      unassignedPermissions: []
    }
    return {...stateProps, ...ownProps}
  }

  const role = state.activeRoleTray.role
  const isBaseRole = roleIsBaseRole(role)
  const displayedRoles = state.roles.filter(r => r.displayed)
  const displayedPermissions = state.permissions.filter(p => p.displayed)
  const permissions = getPermissionsWithLabels(displayedPermissions, role.permissions)

  const allBaseRoles = displayedRoles.reduce((acc, r) => {
    if (roleIsBaseRole(r)) {
      acc.push(r)
    }
    return acc
  }, [])

  // TODO is there ever a situation where a role is editable but not deletable,
  //      or vice versa? If so, will need to figure out the logic for that and
  //      udpate the flags here to match.
  const stateProps = {
    assignedPermissions: permissions.filter(p => p.enabled),
    assignedTo: 'todo',
    basedOn: isBaseRole ? null : getBaseRoleLabel(role, state),
    baseRoleLabels: allBaseRoles.map(r => r.label),
    changedBy: 'todo',
    deletable: !isBaseRole,
    editable: !isBaseRole,
    label: role.label,
    lastChanged: 'todo',
    open: true,
    unassignedPermissions: permissions.filter(p => !p.enabled)
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  hideTray: actions.hideAllTrays
}

export const ConnectedRoleTray = connect(
  mapStateToProps,
  mapDispatchToProps
)(RoleTray)
