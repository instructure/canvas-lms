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
import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome, Rating} from '@canvas/outcomes/react/types/rollup'
import {findRating} from '@canvas/outcomes/react/utils/ratings'
import {BarChart} from './BarChart'
import {colors} from '@instructure/canvas-theme'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface MasteryLevel {
  description: string
  color: string
  count: number
}

export interface MasteryDistributionChartProps {
  outcome: Outcome
  scores: (number | undefined)[]
  width?: number | string
  height?: number | string
  title?: string
  showLegend?: boolean
  showGrid?: boolean
  showLabels?: boolean
  isPreview?: boolean
}

const getMasteryLevelCounts = (
  ratings: Rating[],
  scores: (number | undefined)[],
): MasteryLevel[] => {
  const sortedRatings = [...ratings].sort((a, b) => b.points - a.points)

  const countsMap = new Map<string, MasteryLevel>()

  sortedRatings.forEach(rating => {
    const color = rating.color
      ? rating.color.startsWith('#')
        ? rating.color
        : `#${rating.color}`
      : colors.contrasts.grey4570
    countsMap.set(rating.description || '', {
      description: rating.description || I18n.t('Unknown'),
      color,
      count: 0,
    })
  })

  scores.forEach(score => {
    if (score !== undefined) {
      const rating = findRating(sortedRatings, score)
      if (rating && rating.description) {
        const level = countsMap.get(rating.description)
        if (level) {
          level.count++
        }
      }
    }
  })

  const result: MasteryLevel[] = []

  sortedRatings.forEach(rating => {
    if (rating.description) {
      const level = countsMap.get(rating.description)
      if (level) {
        result.push(level)
      }
    }
  })

  return result
}

export const MasteryDistributionChart: React.FC<MasteryDistributionChartProps> = ({
  outcome,
  scores,
  width = '100%',
  height = 400,
  title,
  showLegend = false,
  showGrid = true,
  isPreview = false,
}) => {
  const masteryLevels = useMemo(
    () => getMasteryLevelCounts(outcome.ratings, scores),
    [outcome.ratings, scores],
  )

  const labels = masteryLevels.map(level => level.description)
  const values = masteryLevels.map(level => level.count)
  const colors = masteryLevels.map(level => level.color)

  return (
    <BarChart
      labels={labels}
      values={values}
      width={width}
      height={height}
      backgroundColor={colors}
      borderWidth={0}
      datasetLabel={I18n.t('Number of Students')}
      title={title}
      yAxisLabel={I18n.t('Number of Students')}
      xAxisLabel={I18n.t('Mastery Level')}
      showLegend={showLegend}
      showGrid={showGrid}
      maintainAspectRatio={false}
      isPreview={isPreview}
    />
  )
}
