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
import {connect} from 'react-redux'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconPublish from '@instructure/ui-icons/lib/Solid/IconPublish'
import IconTrouble from '@instructure/ui-icons/lib/Line/IconTrouble'
import IconLock from '@instructure/ui-icons/lib/Solid/IconLock'
import View from '@instructure/ui-layout/lib/components/View'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Menu, {
  MenuItem,
  MenuItemGroup,
  MenuItemSeparator
} from '@instructure/ui-menu/lib/components/Menu'

import actions from '../actions'
import propTypes from '../propTypes'

export default class PermissionButton extends Component {
  static propTypes = {
    cleanFocus: PropTypes.func.isRequired,
    handleClick: PropTypes.func.isRequired,
    permission: propTypes.rolePermission.isRequired,
    permissionName: PropTypes.string.isRequired,
    courseRoleId: PropTypes.string.isRequired,
    setFocus: PropTypes.bool.isRequired
  }

  componentDidMount = () => {
    if (this.props.setFocus) {
      this.button.focus()
      this.props.cleanFocus()
    }
  }

  checkedSelection(enabled, locked) {
    if (enabled && !locked) {
      return 'Enable'
    } else if (enabled && locked) {
      return 'Enable and Lock'
    } else if (!enabled && !locked) {
      return 'Disable'
    } else {
      return 'Disable and Lock'
    }
  }

  renderMenu = () => (
    <Menu
      placement="bottom center"
      trigger={
        <Button
          disabled={this.props.permission.readonly}
          variant="icon"
          size="medium"
          buttonRef={c => (this.button = c)}
        >
          <Text color={this.props.permission.enabled ? 'success' : 'error'}>
            {this.props.permission.enabled ? (
              <IconPublish size="x-small" />
            ) : (
              <IconTrouble size="x-small" />
            )}
          </Text>
        </Button>
      }
    >
      <MenuItemGroup
        label=""
        selected={[
          this.checkedSelection(this.props.permission.enabled, this.props.permission.locked)
        ]}
      >
        <MenuItem
          value={I18n.t('Enable')}
          onClick={() =>
            this.props.handleClick(this.props.permissionName, this.props.courseRoleId, true, false)
          }
        >
          <Text>{I18n.t('Enable')}</Text>
        </MenuItem>
        <MenuItem
          value={I18n.t('Enable and Lock')}
          onClick={() =>
            this.props.handleClick(this.props.permissionName, this.props.courseRoleId, true, true)
          }
        >
          <Text>{I18n.t('Enable and Lock')}</Text>
        </MenuItem>
        <MenuItem
          value={I18n.t('Disable')}
          onClick={() =>
            this.props.handleClick(this.props.permissionName, this.props.courseRoleId, false, false)
          }
        >
          <Text>{I18n.t('Disable')}</Text>
        </MenuItem>
        <MenuItem
          value={I18n.t('Disable and Lock')}
          onClick={() =>
            this.props.handleClick(this.props.permissionName, this.props.courseRoleId, false, true)
          }
        >
          <Text>{I18n.t('Disable and Lock')}</Text>
        </MenuItem>
      </MenuItemGroup>

      <MenuItemSeparator />

      <MenuItem value={I18n.t('Use Default')}>
        <View as="div" textAlign="center">
          <Text>{I18n.t('Use Default')}</Text>
        </View>
      </MenuItem>
    </Menu>
  )

  render() {
    return (
      <View as="div" textAlign="center">
        <Flex justifyItems="center">
          <FlexItem size="20px" />

          <FlexItem size="25px">{this.renderMenu()}</FlexItem>

          <FlexItem size="20px">
            <Text color="primary">{this.props.permission.locked ? <IconLock /> : ''}</Text>
          </FlexItem>
        </Flex>
      </View>
    )
  }
}

function mapStateToProps(state, ownProps) {
  const setFocus =
    ownProps.trayIcon &&
    ownProps.permissionName === state.nextFocus.permissionName &&
    ownProps.courseRoleId === state.nextFocus.roleId
  const stateProps = {
    setFocus
  }
  return {...stateProps, ...ownProps}
}

const mapDispatchToProps = {
  handleClick: actions.modifyPermissions,
  cleanFocus: actions.cleanFocus
}

export const ConnectedPermissionButton = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionButton)
