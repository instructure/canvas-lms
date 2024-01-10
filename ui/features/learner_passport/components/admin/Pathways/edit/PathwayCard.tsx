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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, MilestoneData} from '../../../types'

export type MilestoneCardVariant = 'sidebar' | 'tree'

type PathwayMilestoneCardProps = {
  step: PathwayDetailData | MilestoneData
  variant: MilestoneCardVariant
}

const PathwayMilestoneCard = ({step, variant}: PathwayMilestoneCardProps) => {
  const isPathway = 'first_milestones' in step
  return (
    <View
      as="div"
      background={isPathway ? 'primary-inverse' : 'primary'}
      borderWidth={isPathway ? 'none' : 'small'}
      borderRadius="medium"
      padding="small"
      textAlign="start"
      width={variant === 'sidebar' ? 'auto' : '350px'}
    >
      <Flex as="div" gap="small">
        <div style={{width: '30px', height: '30px', background: 'grey'}} />
        <View as="div">
          {isPathway && (
            <Text as="div" fontStyle="italic">
              End of pathway
            </Text>
          )}
          <Text as="div" weight="bold">
            {step.title}
          </Text>
        </View>
      </Flex>
      {variant === 'tree' ? (
        <View as="div" margin="small 0 0 0">
          <Text as="div">
            <TruncateText maxLines={2} truncate="character">
              {step.description}
            </TruncateText>
          </Text>
        </View>
      ) : null}
    </View>
  )
}

export default PathwayMilestoneCard
