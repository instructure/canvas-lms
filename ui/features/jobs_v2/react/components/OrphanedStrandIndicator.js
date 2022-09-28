/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import React from 'react'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconWarningSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('jobs_v2')

export default function OrphanedStrandIndicator({name, type}) {
  const title = I18n.t('%{type} "%{name}" has no next_in_strand', {name, type})
  return (
    <Tooltip as="span" renderTip={title}>
      <View margin="0 x-small 0 0">
        <IconWarningSolid color="warning" />
      </View>
    </Tooltip>
  )
}
