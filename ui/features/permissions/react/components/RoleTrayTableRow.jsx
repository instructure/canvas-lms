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

import {useScope as createI18nScope} from '@canvas/i18n'
import {bool, func, node, oneOfType, string} from 'prop-types'
import React from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {IconArrowOpenStartSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import GranularCheckbox from './GranularCheckbox'
import PermissionButton from './PermissionButton'
import permissionPropTypes from '@canvas/permissions/react/propTypes'

const I18n = createI18nScope('permissions_role_tray_table_row')

// TODO Pass in props needed to actually generate the button sara is working on
// TODO add expandable-ness to this. Will probably need to make this not a
//      stateless component at that point in time
export default function RoleTrayTableRow({
  description,
  expandable,
  title,
  permission,
  permissionName,
  permissionLabel,
  role,
  permButton: PermButton,
  permCheckbox: PermCheckbox,
}) {
  const isGranular = typeof permission.group !== 'undefined'
  let button

  if (isGranular) {
    button = (
      <PermCheckbox
        permission={role.permissions[permissionName]}
        permissionName={permissionName}
        permissionLabel={permissionLabel}
        roleId={role.id}
        roleLabel={role.label}
      />
    )
  } else {
    button = (
      <PermButton
        permission={role.permissions[permissionName]}
        permissionName={permissionName}
        permissionLabel={permissionLabel}
        roleId={role.id}
        roleLabel={role.label}
        inTray={true}
      />
    )
  }

  return (
    <View as="div">
      <Flex justifyItems="space-between">
        <Flex.Item>
          {expandable && (
            <span className="ic-permissions_role_tray_table_role_expandable">
              <IconButton
                withBorder={false}
                withBackground={false}
                size="small"
                screenReaderLabel={I18n.t('Expand permission')}
              >
                <IconArrowOpenStartSolid />
              </IconButton>
            </span>
          )}

          <Flex
            direction="column"
            width="12em"
            margin={expandable ? '0' : '0 0 0 medium'}
            display="inline-flex"
          >
            <Flex.Item>
              <Text weight="bold" lineHeight="fit" size="small">
                {title}
              </Text>
            </Flex.Item>
            <Flex.Item>
              {description && (
                <Text lineHeight="fit" size="small">
                  {description}
                </Text>
              )}
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item>
          <div className="ic-permissions__cell-content">{button}</div>
        </Flex.Item>
      </Flex>
    </View>
  )
}

RoleTrayTableRow.propTypes = {
  description: string,
  expandable: bool,
  permission: permissionPropTypes.rolePermission.isRequired,
  permissionName: string.isRequired,
  permissionLabel: string.isRequired,
  role: permissionPropTypes.role.isRequired,
  title: string.isRequired,
  permButton: oneOfType([node, func]), // used for tests only
  permCheckbox: oneOfType([node, func]), // used for tests only
}

RoleTrayTableRow.defaultProps = {
  description: '',
  expandable: false,
  permButton: PermissionButton,
  permCheckbox: GranularCheckbox,
}
