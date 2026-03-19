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

import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import StatisticsCard from './StatisticsCard'
import {useResponsiveContext} from '../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

export interface StatisticsData {
  due: number
  missing: number
  submitted: number
}

export interface StatisticsCardsGridProps {
  summary: StatisticsData
  margin?: string
}

const StatisticsCardsGrid: React.FC<StatisticsCardsGridProps> = ({
  summary,
  margin = 'small 0 0 xx-small',
}) => {
  const {isMobile} = useResponsiveContext()
  const statisticsData = useMemo(
    () => [
      {
        key: 'due',
        count: summary.due,
        label: I18n.t('Due'),
        backgroundColor: '#E0EBF5',
      },
      {
        key: 'missing',
        count: summary.missing,
        label: I18n.t('Missing'),
        backgroundColor: '#FCE4E5',
      },
      {
        key: 'submitted',
        count: summary.submitted,
        label: I18n.t('Submitted'),
        backgroundColor: '#DCEEE4',
      },
    ],
    [summary],
  )

  return (
    <Flex gap="x-small" margin={margin} direction={isMobile ? 'column' : 'row'}>
      {statisticsData.map(stat => (
        <Flex.Item key={stat.key} shouldShrink width={isMobile ? '100%' : '33.33%'}>
          <StatisticsCard
            count={stat.count}
            label={stat.label}
            backgroundColor={stat.backgroundColor}
          />
        </Flex.Item>
      ))}
    </Flex>
  )
}

export default StatisticsCardsGrid
