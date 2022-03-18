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
import $ from 'jquery'

import {connect} from 'react-redux'
import PropTypes from 'prop-types'
import React, {Component} from 'react'

import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
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
    unassignedPermissions: PropTypes.arrayOf(permissionPropTypes.permission).isRequired
  }

  static defaultProps = {
    baseRoleLabels: [],
    allRoleLabels: {},
    basedOn: null,
    role: null,
    id: null,
    updateBaseRole: () => {},
    updateRoleName: () => {}
  }

  state = {
    deleteAlertVisable: false,
    editBaseRoleAlertVisable: false,
    editTrayVisable: false,
    newTargetBaseRole: null,
    editRoleLabelErrorMessages: [],
    roleDeleted: false
  }

  // We need this so that if there is an alert displayed inside this tray
  // (such as the delete confirmation alert) it will disapear if we click
  // on a different role then we are currently operating on.
  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.props.id !== nextProps.id) {
      this.clearState()
    }
  }

  onChangeRoleLabel = event => {
    const trimmedValue = event.target.value.trim()
    const isError = trimmedValue !== this.props.label && this.props.allRoleLabels[trimmedValue]
    let errorMessages = []
    if (isError) {
      const message = I18n.t('Cannot change role name to %{label}: already in use', {
        label: trimmedValue
      })
      errorMessages = [{text: message, type: 'error'}]
    }
    this.setState({
      editRoleLabelInput: event.target.value,
      editRoleLabelErrorMessages: errorMessages
    })
  }

  finishDeleteRole = () => {
    this.setState({roleDeleted: true}, this.hideTray)
  }

  returnFocus = () => {
    if (this.state.roleDeleted) {
      $('#permissions-role-filter').focus()
    } else {
      const query = `#ic-permissions__role-header-for-role-${this.props.role.id}`
      const button = $(query).find('button')
      button.focus()
    }
  }

  hideTray = () => {
    this.props.hideTray()
    this.returnFocus()
    this.clearState()
  }

  showEditTray = () => {
    this.setState(
      {
        deleteAlertVisable: false,
        editTrayVisable: true,
        editBaseRoleAlertVisable: false,
        newTargetBaseRole: null,
        editRoleLabelInput: this.props.role.label,
        editRoleLabelErrorMessages: []
      },
      () => this.closeButton.focus()
    )
  }

  clearState(callback) {
    this.setState(
      {
        deleteAlertVisable: false,
        editTrayVisable: false,
        editBaseRoleAlertVisable: false,
        newTargetBaseRole: null,
        editRoleLabelInput: '',
        editRoleLabelErrorMessages: [],
        roleDeleted: false
      },
      /*
      The setTimeout here is to ensure that the callback gets called AFTER react
      is done rendering everything in response to the setState. that is what it
      did even without the setTimout in react <=15.

      In react 16+ setState callbacks (second argument) now fire immediately
      after componentDidMount / componentDidUpdate instead of after all components
      have rendered.
      (see: https://reactjs.org/blog/2017/09/26/react-v16.0.html#breaking-changes)
      so unless we put this in a setTimeout the refs that we try to focus in this
      file may not be set up yet. By putting it in a setTimeout it works the same
      pre and post react 16 and calls the callback AFTER everything has rerendered
      */
      () => setTimeout(callback)
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
    this.clearState(() => this.editButton.focus())
  }

  showDeleteAlert = () => {
    this.setState({
      deleteAlertVisable: true,
      editTrayVisable: false,
      editBaseRoleAlertVisable: false,
      newTargetBaseRole: null
    })
  }

  hideDeleteAlert = () => {
    this.clearState(() => this.deleteButton.focus())
  }

  showEditBaseRoleAlert = baseRoleLabel => {
    this.setState({
      deleteAlertVisable: false,
      editTrayVisable: true,
      editBaseRoleAlertVisable: true,
      newTargetBaseRole: baseRoleLabel
    })
  }

  hideEditBaseRoleAlert = () => {
    this.setState(
      {
        deleteAlertVisable: false,
        editTrayVisable: true,
        editBaseRoleAlertVisable: false,
        newTargetBaseRole: null
      },
      () => this.editRoleInput.focus()
    )
  }

  deleteRole = () => {
    this.props.deleteRole(this.props.role, this.finishDeleteRole, this.hideDeleteAlert)
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
  renderConfirmationAlert = (children, onOk, onCancel) => (
    <div style={{zIndex: 10, position: 'absolute'}}>
      <Dialog open shouldContainFocus>
        <Alert variant="warning" margin="small">
          <View as="block">
            {children}
            <View as="block" margin="small 0 0 0">
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
    return this.renderConfirmationAlert(text, this.deleteRole, this.hideDeleteAlert)
  }

  renderEditBaseRoleAlert = () => {
    const text = (
      <div className="role-tray-edit-base-role-confirm">
        <Text as="p">
          {I18n.t('Warning: All permissions will change to match the selected base role.')}
        </Text>
      </div>
    )
    return this.renderConfirmationAlert(text, this.handleBaseRoleChange, this.hideEditBaseRoleAlert)
  }

  renderCloseButton = () => (
    <Button
      id="close-role-tray-button"
      variant="icon"
      size="small"
      margin="small 0 0 xx-small"
      onClick={this.state.editTrayVisable ? this.hideEditTray : this.hideTray}
      elementRef={c => (this.closeButton = c)}
    >
      {this.state.editTrayVisable ? (
        <IconArrowStartSolid title={I18n.t('Back')} />
      ) : (
        <IconXSolid title={I18n.t('Close')} />
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
    <Button
      variant="icon"
      size="medium"
      id="edit_button"
      onClick={this.showEditTray}
      elementRef={c => (this.editButton = c)}
    >
      <Text color="brand">
        <IconEditLine title={I18n.t('Edit')} />
      </Text>
    </Button>
  )

  renderDeleteButton = () => (
    <Button
      id="delete-role-button"
      variant="icon"
      size="medium"
      onClick={this.showDeleteAlert}
      elementRef={c => (this.deleteButton = c)}
    >
      <Text color="brand">
        <IconTrashLine title={I18n.t('Delete')} />
      </Text>
    </Button>
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
        size="small"
        placement="end"
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
      >
        {/* TODO Once INSTUI-1269 is fixed and in canvas, use shouldReturnFocus
                 open, and defaultFocusElement dialog props instead of the &&
                 we are currently using to complete destroy this component */}
        {this.state.deleteAlertVisable && this.renderDeleteAlert()}
        {this.state.editBaseRoleAlertVisable && this.renderEditBaseRoleAlert()}
        {this.renderCloseButton()}
        <View as="div" padding="small small x-large small">
          {this.state.editTrayVisable ? this.renderEditHeader() : this.renderTrayHeader()}
          {this.renderPermissions()}
        </View>
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
      unassignedPermissions: []
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
    unassignedPermissions: permissions.filter(p => !p.enabled)
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  hideTray: actions.hideAllTrays,
  updateRoleName: actions.updateRoleName,
  updateBaseRole: actions.updateBaseRole,
  deleteRole: actions.deleteRole
}

export const ConnectedRoleTray = connect(mapStateToProps, mapDispatchToProps)(RoleTray)
