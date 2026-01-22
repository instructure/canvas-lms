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
import React, {useEffect, useMemo, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {svgUrl} from '@canvas/outcomes/react/utils/icons'
import {BarChart} from './BarChart'
import type {Chart as ChartJS, Plugin} from 'chart.js'
import {RatingDistribution} from '@canvas/outcomes/react/types/mastery_distribution'

const I18n = createI18nScope('learning_mastery_gradebook')

interface CustomLabel {
  iconUrl: string
  text: string
}

const loadIcons = (
  labels: CustomLabel[],
  imagesRef: React.MutableRefObject<Map<string, HTMLImageElement>>,
): Promise<void>[] => {
  return labels.map(
    label =>
      new Promise<void>(resolve => {
        const img = new Image()
        img.src = label.iconUrl
        img.onload = () => {
          imagesRef.current.set(label.iconUrl, img)
          resolve()
        }
        img.onerror = () => resolve()
      }),
  )
}

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
}) => {
  const imagesRef = useRef<Map<string, HTMLImageElement>>(new Map())
  const [imagesLoaded, setImagesLoaded] = useState(false)

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

  const labels = masteryLevels.map(level => level.description)
  const values = masteryLevels.map(level => level.count)
  const colors = masteryLevels.map(level => level.color)

  // Create custom labels with icons and counts (only if not in preview mode)
  const customLabels: CustomLabel[] | undefined = useMemo(() => {
    if (isPreview) return undefined
    return masteryLevels.map(level => ({
      iconUrl: svgUrl(level.points, outcome.mastery_points),
      text: level.count.toString(),
    }))
  }, [masteryLevels, outcome.mastery_points, isPreview])

  // Load images for custom labels
  useEffect(() => {
    if (!customLabels || customLabels.length === 0) {
      setImagesLoaded(true)
      return
    }

    setImagesLoaded(false)
    Promise.all(loadIcons(customLabels, imagesRef)).then(() => {
      setImagesLoaded(true)
    })
  }, [customLabels])

  // Custom plugin to draw icons and counts below the bars
  const customLabelsPlugin: Plugin<'bar'> = useMemo(
    () => ({
      id: 'customLabels',
      afterDraw(chart: ChartJS<'bar'>) {
        if (!customLabels || customLabels.length === 0) return

        const {ctx: chartCtx, scales, chartArea} = chart
        const xScale = scales.x
        const iconSize = 12
        const textIconGap = 4
        const yPosition = chartArea.bottom + 10

        customLabels.forEach((label, index) => {
          const x = xScale.getPixelForValue(index)
          const img = imagesRef.current.get(label.iconUrl)

          if (img) {
            const bodyStyle = getComputedStyle(document.body)
            const fontFamily = bodyStyle.fontFamily

            chartCtx.save()
            chartCtx.font = `bold 16px ${fontFamily}`
            const textMetrics = chartCtx.measureText(label.text)
            const textWidth = textMetrics.width
            const totalWidth = iconSize + textIconGap + textWidth
            const textY = yPosition + iconSize / 2

            const iconX = x - totalWidth / 2
            const iconY = textY - iconSize / 2 - 1

            chartCtx.drawImage(img, iconX, iconY, iconSize, iconSize)

            chartCtx.fillStyle = '#000'
            chartCtx.textAlign = 'left'
            chartCtx.textBaseline = 'middle'
            const textX = iconX + iconSize + textIconGap
            chartCtx.fillText(label.text, textX, textY)
            chartCtx.restore()
          }
        })
      },
    }),
    [customLabels],
  )

  const chartPadding = isPreview
    ? {left: 28, right: 30, top: 12, bottom: 12}
    : {left: 0, right: 10, bottom: 26, top: 0}

  return (
    <BarChart
      labels={isPreview ? labels.map(() => '') : labels}
      values={values}
      width={width}
      height={height}
      backgroundColor={colors}
      borderWidth={0}
      borderRadius={
        isPreview ? {topLeft: 1, topRight: 1, bottomLeft: 0, bottomRight: 0} : undefined
      }
      datasetLabel={isPreview ? '' : I18n.t('Number of Students')}
      title={isPreview ? undefined : title}
      showLegend={isPreview ? false : showLegend}
      showXAxisGrid={isPreview ? false : showXAxisGrid}
      showYAxisGrid={isPreview ? false : showYAxisGrid}
      gridColor={gridColor}
      padding={chartPadding}
      maintainAspectRatio={false}
      plugins={customLabels && imagesLoaded ? [customLabelsPlugin] : []}
    />
  )
}
