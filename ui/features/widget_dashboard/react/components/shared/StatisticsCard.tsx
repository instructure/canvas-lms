/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'

interface StatisticsCardProps {
  count: number
  label: string
  backgroundColor: string
}

const StatisticsCard: React.FC<StatisticsCardProps> = ({count, label, backgroundColor}) => {
  const formatCount = (num: number): string => {
    if (num >= 1000) {
      return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'k'
    }
    return num.toLocaleString()
  }

  return (
    <View
      as="div"
      padding="small"
      borderRadius="medium"
      background="primary"
      textAlign="center"
      themeOverride={{
        backgroundPrimary: backgroundColor,
      }}
      data-testid={`statistics-card-${label}`}
    >
      <Text size="x-large" weight="bold">
        {formatCount(count)}
      </Text>
      <View as="div" margin="x-small 0 0">
        <Text size="small">{label}</Text>
      </View>
    </View>
  )
}

export default StatisticsCard
