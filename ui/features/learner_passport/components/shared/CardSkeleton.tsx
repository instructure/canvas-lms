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
import {View} from '@instructure/ui-view'

type CardSkeletonProps = {
  width?: string
  height?: string
}

const CardSkeleton = ({width, height}: CardSkeletonProps) => {
  const CARD_WIDTH = width || '400px'
  const CARD_HEIGHT = height || '200px'

  return (
    <View
      as="div"
      background="secondary"
      width={CARD_WIDTH}
      height={CARD_HEIGHT}
      shadow="resting"
    />
  )
}

function renderCardSkeleton(width: string, height: string) {
  return (
    <Flex gap="medium" wrap="wrap">
      {['a', 'b', 'c'].map(key => (
        <Flex.Item shouldGrow={false} shouldShrink={false} key={key}>
          <CardSkeleton width={width} height={height} />
        </Flex.Item>
      ))}
    </Flex>
  )
}

export default CardSkeleton
export {renderCardSkeleton}
