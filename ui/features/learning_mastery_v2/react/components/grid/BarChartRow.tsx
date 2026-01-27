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
import {MasteryDistributionChart} from '../charts'
import {
  ContributingScoreAlignment,
  ContributingScoresManager,
} from '@canvas/outcomes/react/hooks/useContributingScores'
import {Outcome, Student, StudentRollupData} from '@canvas/outcomes/react/types/rollup'
import {
  BAR_CHART_HEIGHT,
  COLUMN_PADDING,
  COLUMN_WIDTH,
  STUDENT_COLUMN_RIGHT_PADDING,
  STUDENT_COLUMN_WIDTH,
} from '@canvas/outcomes/react/utils/constants'
import {getScoresForOutcome, getScoresForAlignment} from '../../utils/scoreUtils'
import {Column} from '../table/utils'
import {Row} from '../table/Row'
import {Cell} from '../table/Cell'
import {BorderWidth, Shadow} from '@instructure/emotion'

export interface BarChartRowProps {
  rollups: StudentRollupData[]
  students: Student[]
  contributingScores: ContributingScoresManager
  columns: Column[]
  handleKeyDown: (event: React.KeyboardEvent, rowIndex: number, colIndex: number) => void
}

export const BarChartRow: React.FC<BarChartRowProps> = ({
  rollups,
  students,
  contributingScores,
  columns,
  handleKeyDown,
}) => {
  // fixed row index for the bar chart row which is placed above table headers
  const rowIndex = -2

  const commonCellProps = {
    borderWidth: '0' as BorderWidth,
    shadow: 'above' as Shadow,
  }

  return (
    <Row>
      {columns.map((column, columnIndex) => {
        if (column.key === 'student') {
          return (
            <Cell
              id="bar-chart-row-student-cell"
              key="bar-chart-row-student-cell"
              width={`${STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING}px`}
              height={`${BAR_CHART_HEIGHT}px`}
              isSticky
              data-cell-id={`cell-${rowIndex}-${columnIndex}`}
              tabIndex={0}
              onKeyDown={(e: React.KeyboardEvent) => handleKeyDown(e, rowIndex, columnIndex)}
              {...commonCellProps}
            />
          )
        } else if (column.key.startsWith('outcome-')) {
          const outcome = column.data?.outcome as Outcome
          return (
            <Cell
              id={`bar-chart-outcome-${outcome.id}`}
              key={`bar-chart-outcome-${outcome.id}`}
              data-cell-id={`cell-${rowIndex}-${columnIndex}`}
              tabIndex={0}
              onKeyDown={(e: React.KeyboardEvent) => handleKeyDown(e, rowIndex, columnIndex)}
              {...commonCellProps}
            >
              <MasteryDistributionChart
                outcome={outcome}
                scores={getScoresForOutcome(rollups, outcome.id)}
                height={BAR_CHART_HEIGHT}
                width={COLUMN_WIDTH + COLUMN_PADDING}
                isPreview={true}
              />
            </Cell>
          )
        } else if (column.key.startsWith('contributing-score-')) {
          const outcome = column.data?.outcome as Outcome
          const alignment = column.data?.alignment as ContributingScoreAlignment
          return (
            <Cell
              id={`bar-chart-alignment-${outcome.id}-${alignment.alignment_id}`}
              key={alignment.alignment_id}
              data-cell-id={`cell-${rowIndex}-${columnIndex}`}
              tabIndex={0}
              onKeyDown={(e: React.KeyboardEvent) => handleKeyDown(e, rowIndex, columnIndex)}
              {...commonCellProps}
            >
              <MasteryDistributionChart
                outcome={outcome}
                scores={getScoresForAlignment(
                  contributingScores,
                  students,
                  outcome.id,
                  alignment.alignment_id,
                )}
                height={BAR_CHART_HEIGHT}
                width={COLUMN_WIDTH + COLUMN_PADDING}
                isPreview={true}
              />
            </Cell>
          )
        }
      })}
    </Row>
  )
}
