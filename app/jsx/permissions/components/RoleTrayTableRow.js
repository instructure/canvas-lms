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

import I18n from 'i18n!permissions_role_tray_table_row'
import PropTypes from 'prop-types'
import React from 'react'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Container from '@instructure/ui-layout/lib/components/View'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import IconArrowOpenStart from '@instructure/ui-icons/lib/Solid/IconArrowOpenStart'
import Text from '@instructure/ui-elements/lib/components/Text'
import {ConnectedPermissionButton} from './PermissionButton'
import permissionPropTypes from '../propTypes'

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
  role
}) {
  return (
    <Container as="div">
      <Flex justifyItems="space-between">
        <FlexItem>
          {expandable && (
            <span className="ic-permissions_role_tray_table_role_expandable">
              <Button variant="icon" size="small">
                <IconArrowOpenStart title={I18n.t('Expand permission')} />
              </Button>
            </span>
          )}

          <Flex direction="column" width="12em" margin={expandable ? '0' : '0 0 0 medium'} inline>
            <FlexItem>
              <Text weight="bold" lineHeight="fit" size="small">
                {title}
              </Text>
            </FlexItem>
            <FlexItem>
              {description && (
                <Text lineHeight="fit" size="small">
                  {description}
                </Text>
              )}
            </FlexItem>
          </Flex>
        </FlexItem>

        <FlexItem>
          <div className="ic-permissions__cell-content">
            <ConnectedPermissionButton
              permission={permission}
              permissionName={permissionName}
              permissionLabel={permissionLabel}
              roleId={role.id}
              roleLabel={role.label}
              inTray
            />
          </div>
        </FlexItem>
      </Flex>
    </Container>
  )
}

RoleTrayTableRow.propTypes = {
  description: PropTypes.string,
  expandable: PropTypes.bool,
  permission: permissionPropTypes.rolePermission.isRequired,
  permissionName: PropTypes.string.isRequired,
  permissionLabel: PropTypes.string.isRequired,
  role: permissionPropTypes.role.isRequired,
  title: PropTypes.string.isRequired
}

RoleTrayTableRow.defaultProps = {
  description: '',
  expandable: false
}
