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

import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'

import { IconLock, IconUnlock } from './BlueprintLocks'
import propTypes from '../propTypes'
import {itemTypeLabels, changeTypeLabels} from '../labels'

const UnsyncedChange = (props) => {
  const {asset_type, asset_name, change_type, locked} = props.change
  const changeLabel = changeTypeLabels[change_type] || change_type
  const typeLabel = itemTypeLabels[asset_type] || asset_type

  return (
    <tr className="bcs__unsynced-item">
      <td>
        <div className="bcs__unsynced-item__name">
          <Text size="large" color="secondary">
            {locked ? <IconLock /> : <IconUnlock />}
          </Text>
          <View padding="0 0 0 small">
            <Text size="small" weight="bold">{asset_name}</Text>
          </View>
        </div>
      </td>
      <td>
        <Text size="small" weight="bold">{changeLabel}</Text>
      </td>
      <td>
        <Text size="small" weight="bold">{typeLabel}</Text>
      </td>
    </tr>
  )
}


UnsyncedChange.propTypes = {
  change: propTypes.unsyncedChange.isRequired
}

export default UnsyncedChange
