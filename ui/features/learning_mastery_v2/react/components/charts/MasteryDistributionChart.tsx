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
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {svgUrl} from '@canvas/outcomes/react/utils/icons'
import {BarChart} from './BarChart'
import {RatingDistribution} from '@canvas/outcomes/react/types/mastery_distribution'
import {canvas} from '@instructure/ui-themes'
import type {CanvasTheme} from '@instructure/ui-themes'
import {useTheme} from '@instructure/emotion'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface MasteryDistributionChartProps {
  outcome: Outcome
  distributionData: RatingDistribution[]
  width?: number | string
  height?: number | string
  title?: string
  showLegend?: boolean
  showXAxisGrid?: boolean
  showYAxisGrid?: boolean
  gridColor?: string
  isPreview?: boolean
  padding?: {
    left?: number
    right?: number
    top?: number
    bottom?: number
  }
  onBarClick?: (label: string, value: number) => void
  selectedLabel?: string
}

export const MasteryDistributionChart: React.FC<MasteryDistributionChartProps> = ({
  outcome,
  distributionData,
  width = '100%',
  height = 400,
  title,
  showLegend = false,
  showXAxisGrid = false,
  showYAxisGrid = false,
  gridColor,
  isPreview = false,
  onBarClick,
  selectedLabel,
}) => {
  const theme = useTheme() as CanvasTheme
  const themeBorderColor = theme.colors?.contrasts?.grey1424 ?? canvas.colors.contrasts.grey1424
  const masteryLevels = useMemo(() => {
    if (distributionData.length === 0 && outcome.ratings) {
      const sortedRatings = [...outcome.ratings].sort((a, b) => b.points - a.points)
      return sortedRatings.map(rating => {
        const color = rating.color || '666666'
        return {
          description: rating.description || `${rating.points} pts`,
          color: color.startsWith('#') ? color : `#${color}`,
          count: 0,
          points: rating.points,
        }
      })
    }

    return distributionData.map(rating => ({
      description: rating.description,
      color: rating.color.startsWith('#') ? rating.color : `#${rating.color}`,
      count: rating.count,
      points: rating.points,
    }))
  }, [distributionData, outcome.ratings])

  const descriptions = masteryLevels.map(level => level.description)
  const displayLabels = masteryLevels.map(level => String(level.points))
  const values = masteryLevels.map(level => level.count)
  const colors = useMemo(() => {
    return masteryLevels.map(level => {
      if (selectedLabel && level.description !== selectedLabel) {
        return themeBorderColor
      }
      return level.color
    })
  }, [masteryLevels, selectedLabel, themeBorderColor])

  const xAxisImages = useMemo(() => {
    if (isPreview) return undefined
    return masteryLevels.map(level => svgUrl(level.points, outcome.mastery_points))
  }, [masteryLevels, outcome.mastery_points, isPreview])

  const chartDescription = useMemo(() => {
    if (isPreview) return undefined
    return I18n.t('Mastery distribution chart for %{outcome}', {outcome: outcome.title})
  }, [outcome.title, isPreview])

  const pointDescriptions = useMemo(() => {
    if (isPreview) return undefined
    return masteryLevels.map(level =>
      I18n.t('%{description}: %{count} students', {
        description: level.description,
        count: level.count,
      }),
    )
  }, [masteryLevels, isPreview])

  const chartPadding = isPreview
    ? {left: 28, right: 30, top: 12, bottom: 12}
    : {left: 0, right: 10, bottom: 26, top: 0}

  return (
    <BarChart
      labels={isPreview ? descriptions.map(() => '') : displayLabels}
      values={values}
      width={width}
      height={height}
      backgroundColor={colors}
      borderWidth={0}
      borderRadius={isPreview ? 1 : undefined}
      datasetLabel={isPreview ? '' : I18n.t('Number of Students')}
      title={isPreview ? undefined : title}
      showLegend={isPreview ? false : showLegend}
      showXAxisGrid={isPreview ? false : showXAxisGrid}
      showYAxisGrid={isPreview ? false : showYAxisGrid}
      showXAxisTicks={!isPreview}
      gridColor={gridColor}
      padding={chartPadding}
      xAxisLineColor={isPreview ? 'black' : undefined}
      barFocusColor={theme['ic-brand-primary'] ?? canvas['ic-brand-primary']}
      xAxisImages={xAxisImages}
      description={chartDescription}
      pointDescriptions={pointDescriptions}
      onClick={index => {
        onBarClick?.(descriptions[index], values[index])
      }}
    />
  )
}
