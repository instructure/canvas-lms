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
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData} from '../../../types'

export type MilestoneCardVariant = 'sidebar' | 'tree'

type PathwayMilestoneCardProps = {
  pathway: PathwayDetailData
  variant: MilestoneCardVariant
}

const PathwayMilestoneCard = ({pathway, variant}: PathwayMilestoneCardProps) => {
  return (
    <View
      as="div"
      background="primary-inverse"
      borderRadius="medium"
      padding="small"
      width={variant === 'sidebar' ? 'auto' : '350px'}
    >
      <View as="div">
        <Text as="div" weight="bold">
          {pathway.title}
        </Text>
        <Text as="div">End of pathway</Text>
      </View>
      {variant === 'tree' ? (
        <View as="div" margin="small 0 0 0">
          <Text as="div">
            <TruncateText maxLines={2} truncate="character">
              {pathway.description}
            </TruncateText>
          </Text>
        </View>
      ) : null}
    </View>
  )
}

export default PathwayMilestoneCard
