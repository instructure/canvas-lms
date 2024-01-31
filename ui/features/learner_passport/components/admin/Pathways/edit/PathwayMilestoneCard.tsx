/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import type {MilestoneData} from '../../../types'

export type MilestoneCardVariant = 'sidebar' | 'tree'

const BOX_WIDTH = '322'

type PathwayMilestoneCardProps = {
  milestone: MilestoneData
  variant: MilestoneCardVariant
}

const PathwayMilestoneCard = ({milestone, variant}: PathwayMilestoneCardProps) => {
  return (
    <View as="div" width={BOX_WIDTH} borderWidth="small" borderRadius="medium" background="primary">
      <View as="div">
        <Text as="div" weight="bold">
          {milestone.title}
        </Text>
        <Text as="div">End of pathway</Text>
      </View>
      {variant === 'tree' ? (
        <View as="div">
          <Text as="div">{milestone.description}</Text>
        </View>
      ) : null}
    </View>
  )
}

export default PathwayMilestoneCard
