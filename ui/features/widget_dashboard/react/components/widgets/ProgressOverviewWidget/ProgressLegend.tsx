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
import {useScope as createI18nScope} from '@canvas/i18n'
import {List} from '@instructure/ui-list'
import {ColorIndicator} from '@instructure/ui-color-picker'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('widget_dashboard')

export const GRADED_COLOR = '#1E9975'
export const UNGRADED_COLOR = '#2573DF'
export const MISSING_COLOR = '#DB6414'
export const UPCOMING_COLOR = '#D8E7F3'

interface LegendItem {
  color: string
  label: string
  testId: string
}

const legendItems: LegendItem[] = [
  {
    color: GRADED_COLOR,
    label: I18n.t('Graded course work'),
    testId: 'legend-graded-course',
  },
  {
    color: UNGRADED_COLOR,
    label: I18n.t('Ungraded course work'),
    testId: 'legend-ungraded-course',
  },
  {
    color: MISSING_COLOR,
    label: I18n.t('Missing course work'),
    testId: 'legend-missing-work',
  },
  {
    color: UPCOMING_COLOR,
    label: I18n.t('Upcoming available work'),
    testId: 'legend-upcoming',
  },
]

const ProgressLegend: React.FC = () => {
  return (
    <List isUnstyled={true} margin="none" data-testid="progress-legend">
      {legendItems.map(item => (
        <List.Item key={item.testId}>
          <Flex gap="x-small" alignItems="center">
            <Flex.Item>
              <ColorIndicator
                themeOverride={{
                  circleIndicatorSize: '0.75rem',
                }}
                color={item.color}
                data-testid={item.testId}
              />
            </Flex.Item>
            <Flex.Item>
              <Text size="small">{item.label}</Text>
            </Flex.Item>
          </Flex>
        </List.Item>
      ))}
    </List>
  )
}

export default ProgressLegend
