/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'

import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {View} from '@instructure/ui-view'

import {IconLock, IconUnlock} from '@canvas/blueprint-courses/react/components/BlueprintLocks'
import propTypes from '@canvas/blueprint-courses/react/propTypes'
import {itemTypeLabels, changeTypeLabels} from '@canvas/blueprint-courses/react/labels'
import {captionLanguageForLocale} from '@instructure/canvas-media'

const UnsyncedChange = props => {
  const {asset_type, asset_name, change_type, locked, locale} = props.change
  const changeLabel = changeTypeLabels[change_type] || change_type
  const typeLabel = itemTypeLabels[asset_type] || asset_type
  const name = locale ? `${asset_name} (${captionLanguageForLocale(locale)})` : asset_name

  return (
    <Table.Row data-testid="bcs__unsynced-item">
      <Table.Cell>
        <div className="bcs__unsynced-item__name">
          <Text size="large" color="secondary">
            {locked ? <IconLock /> : <IconUnlock />}
          </Text>
          <View padding="0 0 0 small">
            <Text size="small" weight="bold">
              {name}
            </Text>
          </View>
        </div>
      </Table.Cell>
      <Table.Cell>
        <Text size="small" weight="bold">
          {changeLabel}
        </Text>
      </Table.Cell>
      <Table.Cell>
        <Text size="small" weight="bold">
          {typeLabel}
        </Text>
      </Table.Cell>
    </Table.Row>
  )
}

UnsyncedChange.propTypes = {
  change: propTypes.unsyncedChange.isRequired,
}

UnsyncedChange.displayName = 'Row'

export default UnsyncedChange
