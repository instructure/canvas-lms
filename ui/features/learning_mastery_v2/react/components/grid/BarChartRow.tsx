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

import {ContributingScoreAlignment} from '@canvas/outcomes/react/hooks/useContributingScores'
import {
  OutcomeDistribution,
  RatingDistribution,
} from '@canvas/outcomes/react/types/mastery_distribution'
import {Outcome, Student} from '@canvas/outcomes/react/types/rollup'
import {
  BAR_CHART_HEIGHT,
  STUDENT_COLUMN_RIGHT_PADDING,
  STUDENT_COLUMN_WIDTH,
} from '@canvas/outcomes/react/utils/constants'
import {colors} from '@instructure/canvas-theme'
import {Cell} from '@instructure/outcomes-ui/es/components/Gradebook/table/Cell'
import {Row} from '@instructure/outcomes-ui/es/components/Gradebook/table/Row'
import type {Column} from '@instructure/outcomes-ui/lib/components/Gradebook/table/Table'
import React, {useCallback, useEffect, useRef, useState} from 'react'
import {MasteryDistributionChartCell} from '../charts/MasteryDistributionChartCell'

export interface BarChartRowProps {
  columns: Column[]
  outcomeDistributions?: Record<string, OutcomeDistribution>
  distributionStudents?: Student[]
  courseId: string
  isLoading?: boolean
  handleKeyDown: (event: React.KeyboardEvent, rowIndex: number, colIndex: number) => void
  isMobile?: boolean
}

export const BarChartRow: React.FC<BarChartRowProps> = ({
  columns,
  outcomeDistributions,
  distributionStudents,
  courseId,
  isLoading = false,
  handleKeyDown,
  isMobile,
}) => {
  const rowIndex = -2 // Fixed row index for bar chart row
  const [hoveredCellId, setHoveredCellId] = useState<string | null>(null)
  const rowRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const rowEl = rowRef.current
      if (!rowEl) return
      const target = e.target as HTMLElement | null
      if (!target || !rowEl.contains(target)) {
        setHoveredCellId(prev => (prev !== null ? null : prev))
        return
      }
      const cellEl = target.closest('[data-bar-chart-hover-id]') as HTMLElement | null
      const newId = cellEl?.getAttribute('data-bar-chart-hover-id') ?? null
      setHoveredCellId(prev => (prev !== newId ? newId : prev))
    }
    document.addEventListener('mousemove', handleMouseMove)
    return () => document.removeEventListener('mousemove', handleMouseMove)
  }, [])

  const getDistributionForOutcome = useCallback(
    (outcomeId: string | number): RatingDistribution[] | undefined => {
      return outcomeDistributions?.[outcomeId.toString()]?.ratings
    },
    [outcomeDistributions],
  )

  const getDistributionForAlignment = useCallback(
    (outcomeId: string | number, alignmentId: string): RatingDistribution[] | undefined => {
      const outcomeDist = outcomeDistributions?.[outcomeId.toString()]
      return outcomeDist?.alignment_distributions?.[alignmentId]?.ratings
    },
    [outcomeDistributions],
  )

  const getAlignmentDistributionAsOutcome = useCallback(
    (outcomeId: string | number, alignmentId: string): OutcomeDistribution | undefined => {
      const alignmentDist =
        outcomeDistributions?.[outcomeId.toString()]?.alignment_distributions?.[alignmentId]
      if (!alignmentDist) return undefined
      return {
        outcome_id: outcomeId.toString(),
        ratings: alignmentDist.ratings,
        total_students: alignmentDist.total_students,
      }
    },
    [outcomeDistributions],
  )

  return (
    <Row
      setRef={(el: HTMLElement | null) => {
        rowRef.current = el
      }}
    >
      {columns.map((column, columnIndex) => {
        if (column.key === 'student') {
          return (
            <Cell
              id="bar-chart-row-student-cell"
              key="bar-chart-row-student-cell"
              width={`${STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING}px`}
              height={`${BAR_CHART_HEIGHT}px`}
              isSticky={!isMobile}
              data-cell-id={`cell-${rowIndex}-${columnIndex}`}
              tabIndex={0}
              onKeyDown={(e: React.KeyboardEvent) => handleKeyDown(e, rowIndex, columnIndex)}
              boxShadow={`-2px 0 0 0 ${colors.contrasts.grey1214}`}
              shadow="above"
            />
          )
        } else if (column.key.startsWith('outcome-')) {
          const outcome = column.data?.outcome as Outcome
          const cellId = `bar-chart-outcome-${outcome.id}`
          return (
            <Cell
              id={cellId}
              key={cellId}
              data-cell-id={`cell-${rowIndex}-${columnIndex}`}
              data-bar-chart-hover-id={cellId}
              tabIndex={0}
              onKeyDown={(e: React.KeyboardEvent) => handleKeyDown(e, rowIndex, columnIndex)}
              boxShadow={`-2px 0 0 0 ${colors.contrasts.grey1214}`}
              shadow="above"
            >
              <MasteryDistributionChartCell
                key={`outcomes-chart-${outcome.id}`}
                outcome={outcome}
                distributionData={getDistributionForOutcome(outcome.id)}
                outcomeDistribution={outcomeDistributions?.[outcome.id.toString()]}
                distributionStudents={distributionStudents}
                courseId={courseId}
                isLoading={isLoading}
                loadingTitle="Loading mastery distribution"
                isHovered={hoveredCellId === cellId}
              />
            </Cell>
          )
        } else if (column.key.startsWith('contributing-score-')) {
          const outcome = column.data?.outcome as Outcome
          const alignment = column.data?.alignment as ContributingScoreAlignment
          const cellId = `bar-chart-alignment-${outcome.id}-${alignment.alignment_id}`
          return (
            <Cell
              id={cellId}
              key={alignment.alignment_id}
              data-cell-id={`cell-${rowIndex}-${columnIndex}`}
              data-bar-chart-hover-id={cellId}
              tabIndex={0}
              onKeyDown={(e: React.KeyboardEvent) => handleKeyDown(e, rowIndex, columnIndex)}
              boxShadow={`-2px 0 0 0 ${colors.contrasts.grey1214}`}
              shadow="above"
            >
              <MasteryDistributionChartCell
                key={`alignment-chart-${alignment.alignment_id}`}
                outcome={outcome}
                distributionData={getDistributionForAlignment(outcome.id, alignment.alignment_id)}
                outcomeDistribution={getAlignmentDistributionAsOutcome(
                  outcome.id,
                  alignment.alignment_id,
                )}
                distributionStudents={distributionStudents}
                courseId={courseId}
                isLoading={isLoading}
                loadingTitle="Loading alignment distribution"
                isHovered={hoveredCellId === cellId}
              />
            </Cell>
          )
        }

        return null
      })}
    </Row>
  )
}
