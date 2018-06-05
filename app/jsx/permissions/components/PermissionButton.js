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
import {func, string, number} from 'prop-types'
import React from 'react'
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
import AccessibleContent from '@instructure/ui-a11y/lib/components/AccessibleContent'

import actions from '../actions'
import propTypes from '../propTypes'

function checkedSelection(enabled, locked) {
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

export default function PermissionButton(props) {
  const color = props.permission.enabled ? 'success' : 'error'
  return (
    <span>
      <View as="div" textAlign="center">
        <AccessibleContent alt={I18n.t('Menu of options for this permission')}>
          <Menu
            placement="bottom start"
            trigger={
              <Flex justifyItems="center">
                <FlexItem size="20px" />
                <FlexItem size="25px">
                  <Button variant="icon" size="medium">
                    <Text color={color}>
                      {props.permission.enabled ? (
                        <IconPublish size="x-small" />
                      ) : (
                        <IconTrouble size="x-small" />
                      )}
                    </Text>
                  </Button>
                </FlexItem>
                <FlexItem size="20px">
                  <Text color="primary">{props.permission.locked ? <IconLock /> : ''}</Text>
                </FlexItem>
              </Flex>
            }
          >
            <MenuItemGroup
              label=""
              selected={[checkedSelection(props.permission.enabled, props.permission.locked)]}
            >
              <MenuItem
                value={I18n.t('Enable')}
                onClick={() =>
                  props.handleClick(props.permissionName, props.courseRoleId, true, false)
                }
              >
                <Text>{I18n.t('Enable')}</Text>
              </MenuItem>
              <MenuItem
                value={I18n.t('Enable and Lock')}
                onClick={() =>
                  props.handleClick(props.permissionName, props.courseRoleId, true, true)
                }
              >
                <Text>{I18n.t('Enable and Lock')}</Text>
              </MenuItem>
              <MenuItem
                value={I18n.t('Disable')}
      onClick={ () => // eslint-disable-line
                  props.handleClick(props.permissionName, props.courseRoleId, false, false)
                }
              >
                <Text>{I18n.t('Disable')}</Text>
              </MenuItem>
              <MenuItem
                value={I18n.t('Disable and Lock')}
                onClick={() =>
                  props.handleClick(props.permissionName, props.courseRoleId, false, true)
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
        </AccessibleContent>
      </View>
    </span>
  )
}

PermissionButton.propTypes = {
  handleClick: func.isRequired,
  permission: propTypes.rolePermission.isRequired,
  permissionName: string.isRequired,
  courseRoleId: number.isRequired
}

function mapStateToProps(state, ownProps) {
  return ownProps
}

const mapDispatchToProps = {
  handleClick: actions.modifyPermissions
}

export const ConnectedPermissionButton = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionButton)
