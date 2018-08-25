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
import PropTypes from 'prop-types'
import React, {Component} from 'react'
import {renderToString} from 'react-dom/server'
import {connect} from 'react-redux'

import Text from '@instructure/ui-elements/lib/components/Text'
import IconPublish from '@instructure/ui-icons/lib/Solid/IconPublish'
import IconTrouble from '@instructure/ui-icons/lib/Line/IconTrouble'
import IconLock from '@instructure/ui-icons/lib/Solid/IconLock'
import View from '@instructure/ui-layout/lib/components/View'
import Menu, {
  MenuItem,
  MenuItemGroup,
  MenuItemSeparator
} from '@instructure/ui-menu/lib/components/Menu'

import actions from '../actions'
import propTypes from '../propTypes'

const MENU_ID_DEFAULT = 1
const MENU_ID_ENABLED = 2
const MENU_ID_ENABLED_AND_LOCKED = 3
const MENU_ID_DISABLED = 4
const MENU_ID_DISABLED_AND_LOCKED = 5

const BUTTONS = {
  enabled: {
    __html: renderToString(
      <Text color="success">
        <IconPublish size="x-small" />
      </Text>
    )
  },
  disabled: {
    __html: renderToString(
      <Text color="error">
        <IconTrouble size="x-small" />
      </Text>
    )
  }
}

const lockIcon = {
  __html: renderToString(
    <Text color="primary">
      <IconLock />
    </Text>
  )
}

export default class PermissionButton extends Component {
  static propTypes = {
    cleanFocus: PropTypes.func.isRequired,
    fixButtonFocus: PropTypes.func.isRequired,
    handleClick: PropTypes.func.isRequired,
    inTray: PropTypes.bool.isRequired,
    permission: propTypes.rolePermission.isRequired,
    permissionName: PropTypes.string.isRequired,
    permissionLabel: PropTypes.string.isRequired,
    roleLabel: PropTypes.string,
    roleId: PropTypes.string.isRequired,
    setFocus: PropTypes.bool.isRequired,
    onFocus: PropTypes.func.isRequired
  }

  static defaultProps = {
    roleLabel: ''
  }

  state = {
    showMenu: false
  }

  componentDidMount = () => {
    if (this.props.setFocus) {
      this.button.focus()
      this.props.cleanFocus()
    }
  }

  componentDidUpdate = () => {
    if (this.props.setFocus) {
      this.button.focus()
      this.props.cleanFocus()
    }
  }

  setupButtonRef = c => {
    this.button = c
  }

  openMenu = () => {
    this.setState({showMenu: true})
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

  renderButton = () => {
    // We cannot set this as the id, as when this button is a trigger for the
    // instui menu component, it eats the id from this button and replaces it
    // with it's own id. We only have this here for selenium testing
    let classes = `${this.props.permissionName}_${this.props.inTray ? 'tray' : 'table'}_button`
    if (this.props.permission.readonly) {
      classes += ' ic-disabled_permission_button'
    }

    return (
      <button
        aria-label={this.renderAllyScreenReaderTag({
          permission: this.props.permission,
          permissionLabel: this.props.permissionLabel,
          roleLabel: this.props.roleLabel
        })}
        className={classes}
        ref={this.setupButtonRef}
        onClick={this.state.showMenu ? this.closeMenu : this.openMenu}
        disabled={this.props.permission.readonly}
        onFocus={this.props.onFocus}
        dangerouslySetInnerHTML={BUTTONS[this.props.permission.enabled ? 'enabled' : 'disabled']}
      />
    )
  }

  renderAllyScreenReaderTag = ({permission, permissionLabel, roleLabel}) => {
    const {enabled, locked} = permission
    let status = ''
    if (enabled && !locked) {
      status = I18n.t('Enabled')
    } else if (enabled && locked) {
      status = I18n.t('Enabled and Locked')
    } else if (!enabled && !locked) {
      status = I18n.t('Disabled')
    } else {
      status = I18n.t('Disabled and Locked')
    }
    return `${status} ${permissionLabel} ${roleLabel}`
  }

  renderMenu = button => (
    <Menu
      placement="bottom center"
      trigger={button}
      defaultShow={!this.props.inTray}
      onSelect={this.props.inTray ? () => {} : this.closeMenu}
      onDismiss={this.props.inTray ? () => {} : this.closeMenu}
      onBlur={this.props.inTray ? () => {} : this.closeMenu}
      shouldFocusTriggerOnClose={false}
    >
      <MenuItemGroup
        label=""
        selected={[
          this.checkedSelection(
            this.props.permission.enabled,
            this.props.permission.locked,
            this.props.permission.explicit
          )
        ]}
      >
        <MenuItem
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
        </MenuItem>
        <MenuItem
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
        </MenuItem>
        <MenuItem
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
        </MenuItem>
        <MenuItem
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
        </MenuItem>

        <MenuItemSeparator />
        <MenuItem
          id="permission_table_use_default_menu_item"
          value={MENU_ID_DEFAULT}
          onClick={() =>
            this.props.handleClick({
              name: this.props.permissionName,
              id: this.props.roleId,
              enabled: this.props.permission.enabled,
              locked: false,
              explicit: false,
              inTray: this.props.inTray
            })
          }
        >
          <View as="div" textAlign="center">
            <Text>{I18n.t('Use Default')}</Text>
          </View>
        </MenuItem>
      </MenuItemGroup>
    </Menu>
  )

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
          dangerouslySetInnerHTML={lockIcon}
        />
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
