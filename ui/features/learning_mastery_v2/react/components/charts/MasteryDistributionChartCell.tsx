/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import React, {useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {IconButton} from '@instructure/ui-buttons'
import {IconFullScreenLine} from '@instructure/ui-icons'
import {MasteryDistributionChart} from './MasteryDistributionChart'
import {
  OutcomeDistribution,
  RatingDistribution,
} from '@canvas/outcomes/react/types/mastery_distribution'
import {Outcome, Student} from '@canvas/outcomes/react/types/rollup'
import {BAR_CHART_HEIGHT, COLUMN_PADDING} from '@canvas/outcomes/react/utils/constants'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {OutcomeDistributionPopover} from '../popovers/OutcomeDistributionPopover'
import {COLUMN_WIDTH} from '@instructure/outcomes-ui/lib/util/gradebook/constants'

const I18n = createI18nScope('learning_mastery_gradebook')

const CELL_WIDTH = COLUMN_WIDTH + COLUMN_PADDING

export interface MasteryDistributionChartCellProps {
  outcome: Outcome
  distributionData?: RatingDistribution[]
  outcomeDistribution?: OutcomeDistribution
  distributionStudents?: Student[]
  courseId?: string
  isLoading: boolean
  loadingTitle?: string
  isHovered?: boolean
}

const containerStyle: React.CSSProperties = {
  width: `${CELL_WIDTH}px`,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  position: 'relative',
  overflow: 'hidden',
}

export const MasteryDistributionChartCell: React.FC<MasteryDistributionChartCellProps> = ({
  outcome,
  distributionData,
  outcomeDistribution,
  distributionStudents,
  courseId,
  isLoading,
  loadingTitle = 'Loading distribution',
  isHovered = false,
}) => {
  const [focused, setFocused] = useState(false)
  const [isPopoverOpen, setIsPopoverOpen] = useState(false)
  const visible = isHovered || focused

  const canExpand = !!courseId

  const expandButtonTrigger = (
    <IconButton
      withBackground={false}
      withBorder={false}
      size="small"
      renderIcon={<IconFullScreenLine />}
      screenReaderLabel={I18n.t('Expand distribution for %{outcome}', {
        outcome: outcome.title,
      })}
      onClick={() => setIsPopoverOpen(true)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    />
  )

  const expandButton = canExpand && (
    <div
      style={{
        position: 'absolute',
        top: '5px',
        right: '5px',
        zIndex: 1,
        opacity: visible ? 1 : 0,
        pointerEvents: visible ? 'auto' : 'none',
      }}
    >
      {courseId ? (
        <OutcomeDistributionPopover
          outcome={outcome}
          outcomeDistribution={outcomeDistribution}
          distributionStudents={distributionStudents}
          courseId={courseId}
          isOpen={isPopoverOpen}
          onCloseHandler={() => setIsPopoverOpen(false)}
          renderTrigger={expandButtonTrigger}
        />
      ) : (
        expandButtonTrigger
      )}
    </div>
  )

  if (isLoading) {
    return (
      <div style={containerStyle}>
        <View as="div" textAlign="center" width={`${CELL_WIDTH}px`}>
          <Spinner renderTitle={loadingTitle} size="small" />
        </View>
      </div>
    )
  }

  const chartData = distributionData ?? []

  return (
    <div data-testid={`mastery-distribution-chart-cell-${outcome.id}`} style={containerStyle}>
      {expandButton}
      <MasteryDistributionChart
        outcome={outcome}
        distributionData={chartData}
        height={BAR_CHART_HEIGHT}
        width={CELL_WIDTH}
        isPreview={true}
      />
    </div>
  )
}
