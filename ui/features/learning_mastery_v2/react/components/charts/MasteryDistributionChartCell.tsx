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
import React from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {colors} from '@instructure/canvas-theme'
import {MasteryDistributionChart} from './MasteryDistributionChart'
import {RatingDistribution} from '@canvas/outcomes/react/types/mastery_distribution'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {
  BAR_CHART_HEIGHT,
  COLUMN_PADDING,
  COLUMN_WIDTH,
} from '@canvas/outcomes/react/utils/constants'
import {View} from '@instructure/ui-view'

const CELL_WIDTH = COLUMN_WIDTH + COLUMN_PADDING

export interface MasteryDistributionChartCellProps {
  outcome: Outcome
  distributionData?: RatingDistribution[]
  isLoading: boolean
  loadingTitle?: string
}

const containerStyle: React.CSSProperties = {
  width: `${CELL_WIDTH}px`,
  boxShadow: `-2px 0 0 0 ${colors.contrasts.grey1214} inset`,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
}

export const MasteryDistributionChartCell: React.FC<MasteryDistributionChartCellProps> = ({
  outcome,
  distributionData,
  isLoading,
  loadingTitle = 'Loading distribution',
}) => {
  if (isLoading) {
    return (
      <div style={containerStyle}>
        <View as="div" textAlign="center" width={`${CELL_WIDTH}px`}>
          <Spinner renderTitle={loadingTitle} size="small" />
        </View>
      </div>
    )
  }

  if (!distributionData) {
    return (
      <div style={containerStyle}>
        <MasteryDistributionChart
          outcome={outcome}
          distributionData={[]}
          height={BAR_CHART_HEIGHT}
          width={CELL_WIDTH}
          isPreview={true}
        />
      </div>
    )
  }

  return (
    <div style={containerStyle}>
      <MasteryDistributionChart
        outcome={outcome}
        distributionData={distributionData}
        height={BAR_CHART_HEIGHT}
        width={CELL_WIDTH}
        isPreview={true}
      />
    </div>
  )
}
