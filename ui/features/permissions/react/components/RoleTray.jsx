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
import {useScope as useI18nScope} from '@canvas/i18n'

import {connect} from 'react-redux'
import PropTypes from 'prop-types'
import React, {Component} from 'react'

import {Alert} from '@instructure/ui-alerts'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Dialog} from '@instructure/ui-dialog'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {IconArrowStartSolid, IconEditLine, IconTrashLine, IconXSolid} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Tray} from '@instructure/ui-tray'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'

import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import actions from '../actions'
import RoleTrayTable from './RoleTrayTable'
import RoleTrayTableRow from './RoleTrayTableRow'
import permissionPropTypes from '@canvas/permissions/react/propTypes'

import {getPermissionsWithLabels, roleIsBaseRole} from '@canvas/permissions/util'

const I18n = useI18nScope('permissions_role_tray')

export default class RoleTray extends Component {
  static propTypes = {
    id: PropTypes.string,
    assignedPermissions: PropTypes.arrayOf(permissionPropTypes.permission).isRequired,
    baseRoleLabels: PropTypes.arrayOf(PropTypes.string),
    allRoleLabels: PropTypes.objectOf(PropTypes.bool),
    basedOn: PropTypes.string,
    deletable: PropTypes.bool.isRequired,
    editable: PropTypes.bool.isRequired,
    hideTray: PropTypes.func.isRequired,
    deleteRole: PropTypes.func.isRequired,
    label: PropTypes.string.isRequired,
    lastChanged: PropTypes.string.isRequired,
    updateBaseRole: PropTypes.func,
    updateRoleName: PropTypes.func,
    open: PropTypes.bool.isRequired,
    role: permissionPropTypes.role,
    unassignedPermissions: PropTypes.arrayOf(permissionPropTypes.permission).isRequired,
  }

  static defaultProps = {
    baseRoleLabels: [],
    allRoleLabels: {},
    basedOn: null,
    role: null,
    id: null,
    updateBaseRole: () => {},
    updateRoleName: () => {},
  }

  state = {
    deleteAlertVisible: false,
    editBaseRoleAlertVisible: false,
    editTrayVisible: false,
    newTargetBaseRole: null,
    editRoleLabelErrorMessages: [],
    lastTouchedRoleId: undefined,
  }

  // We need this so that if there is an alert displayed inside this tray
  // (such as the delete confirmation alert) it will disapear if we click
  // on a different role then we are currently operating on. We also need
  // to keep track of the most recent role we touched so that we can return
  // focus to it when the tray is closed.
  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.props.id !== nextProps.id) {
      this.clearState()
      if (typeof nextProps.id === 'string') this.setState({lastTouchedRoleId: nextProps.id})
    }
  }

  onChangeRoleLabel = event => {
    const trimmedValue = event.target.value.trim()
    const isError = trimmedValue !== this.props.label && this.props.allRoleLabels[trimmedValue]
    let errorMessages = []
    if (isError) {
      const message = I18n.t('Cannot change role name to %{label}: already in use', {
        label: trimmedValue,
      })
      errorMessages = [{text: message, type: 'error'}]
    }
    this.setState({
      editRoleLabelInput: event.target.value,
      editRoleLabelErrorMessages: errorMessages,
    })
  }

  // After the tray closes, we want to return focus back to the column header
  // for the role we just were looking at. Note that if we've deleted the role,
  // there will no longer be a column header for it, so we'll just return focus
  // to the role filter input in that case.
  returnFocus = () => {
    const id = this.state.lastTouchedRoleId
    const button = document.querySelector(`#ic-permissions__role-header-for-role-${id} button`)
    if (button) {
      button.focus()
    } else {
      const roleFilter = document.getElementById('permissions-role-filter')
      roleFilter?.focus()
    }
  }

  hideTray = () => {
    this.props.hideTray()
    this.clearState()
  }

  showEditTray = () => {
    this.setState(
      {
        deleteAlertVisible: false,
        editTrayVisible: true,
        editBaseRoleAlertVisible: false,
        newTargetBaseRole: null,
        editRoleLabelInput: this.props.role.label,
        editRoleLabelErrorMessages: [],
      },
      () => this.closeButton.focus()
    )
  }

  clearState(callback) {
    this.setState(
      {
        deleteAlertVisible: false,
        editTrayVisible: false,
        editBaseRoleAlertVisible: false,
        newTargetBaseRole: null,
        editRoleLabelInput: '',
        editRoleLabelErrorMessages: [],
      },
      callback
    )
  }

  updateRole = event => {
    if (this.state.editRoleLabelErrorMessages && this.state.editRoleLabelErrorMessages.length > 0) {
      // Don't try to post the edit if we are in error
      return
    }
    const trimmedValue = event.target.value ? event.target.value.trim() : ''
    if (trimmedValue === '') {
      this.setState({editRoleLabelInput: this.props.role.label, editRoleLabelErrorMessages: []})
    } else if (this.props.role.label !== trimmedValue) {
      this.props.updateRoleName(this.props.id, trimmedValue, this.props.basedOn)
    }
  }

  hideEditTray = () => {
    this.clearState(() => setTimeout(() => this.editButton.focus()))
  }

  showDeleteAlert = () => {
    this.setState({
      deleteAlertVisible: true,
      editTrayVisible: false,
      editBaseRoleAlertVisible: false,
      newTargetBaseRole: null,
    })
  }

  hideDeleteAlert = () => {
    this.clearState(() => setTimeout(() => this.deleteButton.focus()))
  }

  showEditBaseRoleAlert = baseRoleLabel => {
    this.setState({
      deleteAlertVisible: false,
      editTrayVisible: true,
      editBaseRoleAlertVisible: true,
      newTargetBaseRole: baseRoleLabel,
    })
  }

  hideEditBaseRoleAlert = () => {
    this.setState({
      deleteAlertVisible: false,
      editTrayVisible: true,
      editBaseRoleAlertVisible: false,
      newTargetBaseRole: null,
    })
  }

  deleteRole = () => {
    this.props.deleteRole(this.props.role, this.hideTray, this.hideDeleteAlert)
  }

  handleBaseRoleChange = () => {
    const onSuccess = () => {
      // TODO flash message?
      this.hideEditBaseRoleAlert()
    }
    const onFail = () => {
      // TODO flash message?
      this.hideEditBaseRoleAlert()
    }
    this.props.updateBaseRole(this.props.role, this.state.newTargetBaseRole, onSuccess, onFail)
  }

  // TODO maybe make this a whole other component we can use/reuse?
  renderConfirmationAlert = (children, isOpen, onOk, onCancel) => (
    <div style={{zIndex: 10, position: 'absolute'}}>
      <Dialog open={isOpen} shouldContainFocus={true} shouldReturnFocus={true}>
        <Alert variant="warning" margin="small">
          <View display="block">
            {children}
            <View display="block" margin="small 0 0 0">
              <Button onClick={onCancel} margin="none xx-small none none">
                <ScreenReaderContent>{children}</ScreenReaderContent>
                {I18n.t('Cancel')}
              </Button>
              <Button onClick={onOk} id="confirm-delete-role" color="primary">
                {I18n.t('Ok')}
              </Button>
            </View>
          </View>
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
    return this.renderConfirmationAlert(
      text,
      this.state.deleteAlertVisible,
      this.deleteRole,
      this.hideDeleteAlert
    )
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
      this.state.editBaseRoleAlertVisible,
      this.handleBaseRoleChange,
      this.hideEditBaseRoleAlert
    )
  }

  renderCloseButton = () => (
    <IconButton
      id="close-role-tray-button"
      withBorder={false}
      withBackground={false}
      size="small"
      margin="small 0 0 xx-small"
      onClick={this.state.editTrayVisible ? this.hideEditTray : this.hideTray}
      elementRef={c => (this.closeButton = c)}
      screenReaderLabel={this.state.editTrayVisible ? I18n.t('Back') : I18n.t('Close')}
    >
      {this.state.editTrayVisible ? <IconArrowStartSolid /> : <IconXSolid />}
    </IconButton>
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
              role={this.props.role}
              permissionLabel={perm.label}
              permissionName={perm.permissionName}
              permission={perm}
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
              role={this.props.role}
              permissionLabel={perm.label}
              permissionName={perm.permissionName}
              permission={perm}
            />
          ))}
        </RoleTrayTable>
      )}
    </div>
  )

  renderEditButton = () => (
    <IconButton
      id="edit_button"
      withBorder={false}
      withBackground={false}
      size="medium"
      color="primary"
      elementRef={c => {
        this.editButton = c
      }}
      onClick={this.showEditTray}
      screenReaderLabel={I18n.t('Edit')}
    >
      <IconEditLine />
    </IconButton>
  )

  renderDeleteButton = () => (
    <IconButton
      id="delete-role-button"
      withBorder={false}
      withBackground={false}
      size="medium"
      color="primary"
      elementRef={c => (this.deleteButton = c)}
      onClick={this.showDeleteAlert}
      screenReaderLabel={I18n.t('Delete')}
    >
      <IconTrashLine />
    </IconButton>
  )

  renderTrayHeader = () => (
    <div>
      <Flex alignItems="start" justifyItems="space-between">
        <Flex.Item>
          <View as="div">
            <div style={{maxWidth: '225px'}}>
              <Heading id="general_tray_header" level="h3" as="h2">
                {this.props.label}
              </Heading>
            </div>
            {this.props.basedOn && (
              <Text size="small" className="role-tray-based-on">
                {I18n.t('Based on: %{basedOn}', {basedOn: this.props.basedOn})}
              </Text>
            )}
          </View>
        </Flex.Item>
        <Flex.Item>
          {this.props.editable && this.renderEditButton()}
          {this.props.deletable && this.renderDeleteButton()}
        </Flex.Item>
      </Flex>

      <View as="div" margin="small 0 medium 0">
        <Flex direction="column">
          <Flex.Item>
            <Text className="role-tray-last-changed">
              <span>
                <FriendlyDatetime
                  prefix={I18n.t('Last changed:')}
                  dateTime={this.props.lastChanged}
                />
              </span>
            </Text>
          </Flex.Item>
        </Flex>
      </View>
    </div>
  )

  renderBaseRoleSelector = () => (
    <View as="div" margin="medium 0 large 0">
      <SimpleSelect
        renderLabel={I18n.t('Base Type')}
        defaultValue={this.props.basedOn}
        onChange={(_event, option) => this.showEditBaseRoleAlert(option.value)}
        inputRef={c => (this.editRoleInput = c)}
      >
        {this.props.baseRoleLabels.map(label => (
          <SimpleSelect.Option id={label} key={label} value={label}>
            {label}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </View>
  )

  renderEditHeader = () => (
    <div>
      <Heading level="h3" as="h2" id="edit_tray_header">
        {I18n.t('Edit %{label}', {label: this.props.label})}
      </Heading>

      <View as="div" margin="medium 0 large 0">
        <TextInput
          renderLabel={I18n.t('Role Name')}
          name="edit_name_box"
          value={this.state.editRoleLabelInput}
          messages={this.state.editRoleLabelErrorMessages}
          onBlur={this.updateRole}
          onChange={this.onChangeRoleLabel}
        />
      </View>

      {/*
       * this is not currently possible due to limitations in the api. once we
       * update the API we should be able to uncomment this, update our apiClient,
       * and have everything just work :fingers-crossed:
       */}
      {false && this.renderBaseRoleSelector()}
    </div>
  )

  render() {
    return (
      <Tray
        label={this.props.label}
        open={this.props.open}
        onDismiss={this.hideTray}
        onClose={this.returnFocus.bind(this)}
        size="small"
        placement="end"
        liveRegion={getLiveRegion}
      >
        {this.renderDeleteAlert()}
        {this.renderEditBaseRoleAlert()}
        {this.renderCloseButton()}
        {this.props.label.length > 0 && (
          <View as="div" padding="small small x-large small">
            {this.state.editTrayVisible ? this.renderEditHeader() : this.renderTrayHeader()}
            {this.renderPermissions()}
          </View>
        )}
      </Tray>
    )
  }
}

function getBaseRoleLabel(role, state) {
  // Account roles do not have the whole based on inheritance thing going on.
  if (role.base_role_type === 'AccountMembership') {
    return null
  }
  return state.roles.find(ele => ele.role === role.base_role_type).label
}

function mapStateToProps(state, ownProps) {
  if (state.activeRoleTray === null) {
    const stateProps = {
      basedOn: null,
      deletable: false,
      editable: false,
      label: '',
      lastChanged: '',
      open: false,
      assignedPermissions: [],
      unassignedPermissions: [],
    }
    return {...stateProps, ...ownProps}
  }

  const role = state.roles.find(r => r.id === state.activeRoleTray.roleId)
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

  const allRoleLabels = state.roles.reduce((obj, r) => {
    obj[r.label] = true
    return obj
  }, {})

  // TODO is there ever a situation where a role is editable but not deletable,
  //      or vice versa? If so, will need to figure out the logic for that and
  //      udpate the flags here to match.
  const stateProps = {
    contextId: state.contextId,
    assignedPermissions: permissions.filter(p => p.enabled),
    basedOn: isBaseRole ? null : getBaseRoleLabel(role, state),
    baseRoleLabels: allBaseRoles.map(r => r.label),
    allRoleLabels,
    deletable: !isBaseRole && role.account?.id === state.contextId,
    editable: !isBaseRole && role.account?.id === state.contextId,
    label: role.label,
    id: role.id,
    lastChanged: role.last_updated_at,
    open: true,
    role,
    unassignedPermissions: permissions.filter(p => !p.enabled),
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  hideTray: actions.hideAllTrays,
  updateRoleName: actions.updateRoleName,
  updateBaseRole: actions.updateBaseRole,
  deleteRole: actions.deleteRole,
}

export const ConnectedRoleTray = connect(mapStateToProps, mapDispatchToProps)(RoleTray)
