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

import I18n from 'i18n!permission_button'
import {func, bool, string} from 'prop-types'
import React, {Component} from 'react'
import {connect} from 'react-redux'
import {Text} from '@instructure/ui-elements'
import {
  IconPublishSolid,
  IconTroubleLine,
  IconLockSolid,
  IconOvalHalfSolid
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-layout'
import {Menu} from '@instructure/ui-menu'
import {IconButton} from '@instructure/ui-buttons'

import actions from '../actions'
import propTypes, {ENABLED_FOR_NONE, ENABLED_FOR_ALL, ENABLED_FOR_PARTIAL} from '../propTypes'

const MENU_ID_DEFAULT = 1
const MENU_ID_ENABLED = 2
const MENU_ID_ENABLED_AND_LOCKED = 3
const MENU_ID_DISABLED = 4
const MENU_ID_DISABLED_AND_LOCKED = 5

export default class PermissionButton extends Component {
  static propTypes = {
    cleanFocus: func.isRequired,
    fixButtonFocus: func.isRequired,
    handleClick: func.isRequired,
    inTray: bool.isRequired,
    permission: propTypes.rolePermission.isRequired,
    permissionName: string.isRequired,
    permissionLabel: string.isRequired,
    roleLabel: string,
    roleId: string.isRequired,
    setFocus: bool.isRequired,
    onFocus: func
  }

  static defaultProps = {
    roleLabel: ''
  }

  state = {
    showMenu: false
  }

  componentDidMount() {
    if (this.props.setFocus) {
      this.button.focus()
      this.props.cleanFocus()
    }
  }

  componentDidUpdate() {
    if (this.props.setFocus) {
      this.button.focus()
      this.props.cleanFocus()
    }
  }

  setupButtonRef = c => {
    this.button = c
  }

  closeMenu = () => {
    this.setState({showMenu: false}, () =>
      this.props.fixButtonFocus({
        permissionName: this.props.permissionName,
        roleId: this.props.roleId,
        inTray: this.props.inTray
      })
    )
  }

  toggleMenu = () => {
    if (this.state.showMenu) {
      this.closeMenu()
      return
    }
    this.setState({showMenu: true})
  }

  checkedSelection(enabled, locked, explicit) {
    if (!explicit) {
      return MENU_ID_DEFAULT
    } else if (enabled && !locked) {
      return MENU_ID_ENABLED
    } else if (enabled && locked) {
      return MENU_ID_ENABLED_AND_LOCKED
    } else if (!enabled && !locked) {
      return MENU_ID_DISABLED
    } else {
      return MENU_ID_DISABLED_AND_LOCKED
    }
  }

  renderButton() {
    const {enabled} = this.props.permission

    function stateIcon() {
      if (enabled === ENABLED_FOR_NONE) return IconTroubleLine
      if (enabled === ENABLED_FOR_ALL) return IconPublishSolid
      if (enabled === ENABLED_FOR_PARTIAL) return IconOvalHalfSolid
    }

    const stateColor = enabled === ENABLED_FOR_NONE ? 'danger' : 'success'

    return (
      <IconButton
        elementRef={this.setupButtonRef}
        onClick={this.toggleMenu}
        onFocus={this.props.onFocus}
        interaction={this.props.permission.readonly ? 'disabled' : 'enabled'}
        size="large"
        withBackground={false}
        withBorder={false}
        color={stateColor}
        screenReaderLabel={this.renderAllyScreenReaderTag({
          permission: this.props.permission,
          permissionLabel: this.props.permissionLabel,
          roleLabel: this.props.roleLabel
        })}
      >
        {stateIcon()}
      </IconButton>
    )
  }

  renderAllyScreenReaderTag({permission, permissionLabel, roleLabel}) {
    const {enabled, locked} = permission
    let status = ''
    if (enabled === ENABLED_FOR_ALL && !locked) {
      status = I18n.t('Enabled')
    } else if (enabled === ENABLED_FOR_ALL && locked) {
      status = I18n.t('Enabled and Locked')
    } else if (enabled === ENABLED_FOR_PARTIAL && !locked) {
      status = I18n.t('Partially enabled')
    } else if (enabled === ENABLED_FOR_PARTIAL && locked) {
      status = I18n.t('Partially enabled and Locked')
    } else if (enabled === ENABLED_FOR_NONE && !locked) {
      status = I18n.t('Disabled')
    } else {
      status = I18n.t('Disabled and Locked')
    }
    return `${status} ${permissionLabel} ${roleLabel}`
  }

  renderMenu(button) {
    return (
      <Menu
        placement="bottom center"
        trigger={button}
        defaultShow={!this.props.inTray}
        onSelect={this.props.inTray ? () => {} : this.closeMenu}
        onDismiss={this.props.inTray ? () => {} : this.closeMenu}
        onBlur={this.props.inTray ? () => {} : this.closeMenu}
        shouldFocusTriggerOnClose={false}
      >
        <Menu.Group
          label=""
          selected={[
            this.checkedSelection(
              this.props.permission.enabled,
              this.props.permission.locked,
              this.props.permission.explicit
            )
          ]}
        >
          <Menu.Item
            id="permission_table_enable_menu_item"
            value={MENU_ID_ENABLED}
            onClick={() =>
              this.props.handleClick({
                name: this.props.permissionName,
                id: this.props.roleId,
                enabled: true,
                locked: false,
                explicit: true,
                inTray: this.props.inTray
              })
            }
          >
            <Text>{I18n.t('Enable')}</Text>
          </Menu.Item>
          <Menu.Item
            id="permission_table_enable_and_lock_menu_item"
            value={MENU_ID_ENABLED_AND_LOCKED}
            onClick={() =>
              this.props.handleClick({
                name: this.props.permissionName,
                id: this.props.roleId,
                enabled: true,
                locked: true,
                explicit: true,
                inTray: this.props.inTray
              })
            }
          >
            <Text>{I18n.t('Enable and Lock')}</Text>
          </Menu.Item>
          <Menu.Item
            id="permission_table_disable_menu_item"
            value={MENU_ID_DISABLED}
            onClick={() =>
              this.props.handleClick({
                name: this.props.permissionName,
                id: this.props.roleId,
                enabled: false,
                locked: false,
                explicit: true,
                inTray: this.props.inTray
              })
            }
          >
            <Text as="span">{I18n.t('Disable')}</Text>
          </Menu.Item>
          <Menu.Item
            id="permission_table_disable_and_lock_menu_item"
            value={MENU_ID_DISABLED_AND_LOCKED}
            onClick={() =>
              this.props.handleClick({
                name: this.props.permissionName,
                id: this.props.roleId,
                enabled: false,
                locked: true,
                explicit: true,
                inTray: this.props.inTray
              })
            }
          >
            <Text>{I18n.t('Disable and Lock')}</Text>
          </Menu.Item>

          <Menu.Separator />
          <Menu.Item
            id="permission_table_use_default_menu_item"
            value={MENU_ID_DEFAULT}
            onClick={() =>
              this.props.handleClick({
                name: this.props.permissionName,
                id: this.props.roleId,
                locked: false,
                explicit: false,
                inTray: this.props.inTray
              })
            }
          >
            <View as="div" textAlign="center">
              <Text>{I18n.t('Use Default')}</Text>
            </View>
          </Menu.Item>
        </Menu.Group>
      </Menu>
    )
  }

  render() {
    // Note: for performance, we do not initialize the menu button at all until
    //       the button is clicked, unless we are in a tray (which has significatnly
    //       less buttons). The reason we do something different if the button is
    //       in the tray is because focus is able to escape from the tray if we
    //       do it the other way, and performance of the tray is not currently
    //       an issue.
    const button = this.renderButton()
    return (
      <div
        id={`${this.props.permissionName}_${this.props.roleId}`}
        className="ic-permissions__permission-button-container"
      >
        <div>{this.props.inTray || this.state.showMenu ? this.renderMenu(button) : button}</div>
        <div
          className={
            this.props.permission.locked && this.props.permission.explicit
              ? null
              : 'ic-hidden-button'
          }
        >
          <Text color="primary">
            <IconLockSolid />
          </Text>
        </div>
      </div>
    )
  }
}

function mapStateToProps(state, ownProps) {
  const targetFocusButton =
    ownProps.permissionName === state.nextFocus.permissionName &&
    ownProps.roleId === state.nextFocus.roleId
  const targetFocusArea =
    (state.nextFocus.targetArea === 'tray' && ownProps.inTray) ||
    (state.nextFocus.targetArea === 'table' && !ownProps.inTray)

  const stateProps = {
    setFocus: targetFocusButton && targetFocusArea
  }
  return {...stateProps, ...ownProps}
}

const mapDispatchToProps = {
  handleClick: actions.modifyPermissions,
  fixButtonFocus: actions.fixButtonFocus,
  cleanFocus: actions.cleanFocus
}

export const ConnectedPermissionButton = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionButton)
