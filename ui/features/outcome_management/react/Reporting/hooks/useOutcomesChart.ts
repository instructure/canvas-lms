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

import {useEffect, useRef, useMemo} from 'react'
import {
  Chart as ChartJS,
  LineController,
  LineElement,
  PointElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend,
} from 'chart.js'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {OutcomeIconType, ProficiencyRating} from '@canvas/outcomes/react/utils/icons'
import {LMGBScoreReporting, ScoreType} from '../types'
import {theme} from '@instructure/canvas-theme'
import useLMGBContext from '@canvas/outcomes/react/hooks/useLMGBContext'
import {shouldUseNumbers} from '@canvas/outcomes/react/utils/masteryScaleLogic'

const I18n = createI18nScope('outcome_management')

const Y_MAX = 4.5

ChartJS.register(
  LineController,
  LineElement,
  PointElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend,
)

/*
 * Default mastery level configuration for backward compatibility
 */
const DEFAULT_MASTERY_LEVEL_CONFIGS: Array<{level: OutcomeIconType; value: number}> = [
  {level: 'remediation', value: 1},
  {level: 'near_mastery', value: 2},
  {level: 'mastery', value: 3},
  {level: 'exceeds_mastery', value: 4},
] as const

const SCORE_TYPES: ScoreType[] = ['quiz', 'discussion', 'assignment'] as const

/**
 * Builds mastery level configs from proficiency ratings
 * Maps actual point values to icon types based on level count and mastery position
 * Returns configs for all ratings, whether using icons or numbers
 */
const buildMasteryLevelConfigs = (
  ratings?: ProficiencyRating[],
): Array<{level: OutcomeIconType; value: number}> => {
  if (!ratings || ratings.length === 0) {
    return DEFAULT_MASTERY_LEVEL_CONFIGS
  }

  // Sort ratings by points descending (highest to lowest)
  const sortedRatings = [...ratings].sort((a, b) => b.points - a.points)
  const masteryIndex = sortedRatings.findIndex(r => r.mastery === true)

  // For >5 levels or cases where numbers will be used, still return configs
  // The level field will be ignored when numbers are displayed
  if (sortedRatings.length > 5) {
    return sortedRatings.map(rating => ({
      level: 'mastery', // Placeholder, won't be used for icon rendering
      value: rating.points,
    }))
  }

  switch (sortedRatings.length) {
    case 1:
      return [{level: 'mastery', value: sortedRatings[0].points}]

    case 2:
      if (masteryIndex === 0) {
        // Mastery at highest level
        return [
          {level: 'near_mastery', value: sortedRatings[1].points},
          {level: 'mastery', value: sortedRatings[0].points},
        ]
      } else {
        // Mastery at lowest level
        return [
          {level: 'mastery', value: sortedRatings[1].points},
          {level: 'exceeds_mastery', value: sortedRatings[0].points},
        ]
      }

    case 3:
      if (masteryIndex === 0) {
        // Mastery at highest level
        return [
          {level: 'remediation', value: sortedRatings[2].points},
          {level: 'near_mastery', value: sortedRatings[1].points},
          {level: 'mastery', value: sortedRatings[0].points},
        ]
      } else if (masteryIndex === 1) {
        // Mastery at middle level
        return [
          {level: 'near_mastery', value: sortedRatings[2].points},
          {level: 'mastery', value: sortedRatings[1].points},
          {level: 'exceeds_mastery', value: sortedRatings[0].points},
        ]
      } else {
        // Mastery at lowest level - will use numbers, but return configs for grid lines
        return sortedRatings.map(rating => ({
          level: 'mastery', // Placeholder
          value: rating.points,
        }))
      }

    case 4:
      return [
        {level: 'remediation', value: sortedRatings[3].points},
        {level: 'near_mastery', value: sortedRatings[2].points},
        {level: 'mastery', value: sortedRatings[1].points},
        {level: 'exceeds_mastery', value: sortedRatings[0].points},
      ]

    case 5:
      return [
        {level: 'no_evidence', value: sortedRatings[4].points},
        {level: 'remediation', value: sortedRatings[3].points},
        {level: 'near_mastery', value: sortedRatings[2].points},
        {level: 'mastery', value: sortedRatings[1].points},
        {level: 'exceeds_mastery', value: sortedRatings[0].points},
      ]

    default:
      return DEFAULT_MASTERY_LEVEL_CONFIGS
  }
}

const loadIcons = <T>(
  types: readonly T[],
  iconRef: React.MutableRefObject<{[key: string]: HTMLImageElement}>,
  keyExtractor: (item: T) => string,
): Promise<void>[] => {
  return types.map(item => {
    const key = keyExtractor(item)
    return new Promise<void>(resolve => {
      const img = new Image()
      img.src = `/images/outcomes/${key}.svg`
      img.onload = () => {
        iconRef.current[key] = img
        resolve()
      }
      img.onerror = () => resolve()
    })
  })
}

export const useOutcomesChart = (
  scores: LMGBScoreReporting[],
  outcomeRatings?: ProficiencyRating[],
) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const chartRef = useRef<ChartJS<'line'> | null>(null)
  const masteryIconsRef = useRef<{[key: string]: HTMLImageElement}>({})
  const scoreTypeIconsRef = useRef<{[key: string]: HTMLImageElement}>({})

  // Get proficiency ratings from outcome-specific data, or fall back to context
  const {outcomeProficiency} = useLMGBContext()
  const proficiencyRatings = outcomeRatings || outcomeProficiency?.ratings

  // Show 5 latest scores - needs to be calculated first
  const sortedScores = useMemo(
    () =>
      [...scores]
        .sort((a, b) => new Date(a.submitted_at).getTime() - new Date(b.submitted_at).getTime())
        .slice(-5),
    [scores],
  )

  // Build mastery level configs from proficiency ratings
  const masteryLevelConfigs = useMemo(
    () => buildMasteryLevelConfigs(proficiencyRatings),
    [proficiencyRatings],
  )

  // Determine whether to use numbers or icons on Y-axis
  const useNumbers = useMemo(() => {
    if (!proficiencyRatings || proficiencyRatings.length === 0) return false
    const sortedRatings = [...proficiencyRatings].sort((a, b) => b.points - a.points)
    const masteryIndex = sortedRatings.findIndex(r => r.mastery === true)
    return shouldUseNumbers(proficiencyRatings.length, masteryIndex)
  }, [proficiencyRatings])

  // Find mastery point value (where mastery: true)
  const masteryPointValue = useMemo(() => {
    if (!proficiencyRatings || proficiencyRatings.length === 0) {
      // Default to value 3 in default configs
      return DEFAULT_MASTERY_LEVEL_CONFIGS.find(c => c.level === 'mastery')?.value ?? 3
    }
    const masteryRating = proficiencyRatings.find(r => r.mastery === true)
    return masteryRating?.points ?? proficiencyRatings[1]?.points ?? 3
  }, [proficiencyRatings])

  // Calculate Y-axis range
  const {yMin, yMax} = useMemo(() => {
    const configValues = masteryLevelConfigs.map(c => c.value)
    const scoreValues = sortedScores.map(s => s.score).filter(s => s != null)

    // Combine both config values and actual score values to determine range
    const allValues = [...configValues, ...scoreValues]

    if (allValues.length === 0) {
      return {yMin: 0, yMax: Y_MAX}
    }

    const min = Math.min(...allValues)
    const max = Math.max(...allValues)

    // If using default 1-4 scale and scores fit within it, use original min/max
    if (
      configValues.length > 0 &&
      Math.min(...configValues) === 1 &&
      Math.max(...configValues) === 4 &&
      min >= 0 &&
      max <= Y_MAX
    ) {
      return {yMin: 0, yMax: Y_MAX}
    }

    // For custom scales or when scores exceed default range, calculate dynamic range
    const minValue = Math.min(0, min) // Ensure we start at 0 or lower
    const maxValue = max + (max - min) * 0.15 // Add 15% padding at top

    return {
      yMin: minValue,
      yMax: maxValue,
    }
  }, [masteryLevelConfigs, sortedScores])

  useEffect(() => {
    if (!canvasRef.current || sortedScores.length === 0) return
    if (!masteryLevelConfigs || masteryLevelConfigs.length === 0) {
      return
    }

    // Only load mastery icons if we're using icons (not numbers)
    const loadMasteryIcons = useNumbers
      ? []
      : loadIcons(masteryLevelConfigs, masteryIconsRef, ({level}) => level)
    const loadScoreTypeIcons = loadIcons(SCORE_TYPES, scoreTypeIconsRef, type => type)

    Promise.all([...loadMasteryIcons, ...loadScoreTypeIcons]).then(() => {
      if (!canvasRef.current) return

      const labels = sortedScores.map(score => {
        const date = new Date(score.submitted_at)
        return date.toLocaleDateString(I18n.currentLocale(), {month: 'numeric', day: 'numeric'})
      })

      const data = sortedScores.map(score => score.score)

      // Debug: Check if data fits within Y-axis range
      const maxDataValue = Math.max(...data.filter(v => v != null))
      const minDataValue = Math.min(...data.filter(v => v != null))
      if (maxDataValue > yMax || minDataValue < yMin) {
        console.warn('Data values outside Y-axis range:', {
          dataRange: [minDataValue, maxDataValue],
          yAxisRange: [yMin, yMax],
        })
      }

      chartRef.current?.destroy()

      // Custom plugin to draw icons on Y-axis and X-axis
      const iconsPlugin = {
        id: 'icons',
        afterDraw: (chart: ChartJS) => {
          const ctx = chart.ctx
          const yScale = chart.scales.y
          const xScale = chart.scales.x
          const chartArea = chart.chartArea

          // Draw Y-axis icons only when NOT using numbers
          if (!useNumbers) {
            masteryLevelConfigs.forEach(({level, value}) => {
              const icon = masteryIconsRef.current[level]
              if (!icon) return

              const yPosition = yScale.getPixelForValue(value)
              const iconSize = 12
              const xPosition = chartArea.left - iconSize - 14

              ctx.drawImage(icon, xPosition, yPosition - iconSize / 2, iconSize, iconSize)
            })
          }

          if (xScale.ticks) {
            // Draw X-axis icons
            xScale.ticks.forEach((_tick, index) => {
              const scoreData = sortedScores[index]
              if (!scoreData) return

              // Use the type from the score data, or default to 'assignment'
              const assetType: ScoreType =
                (scoreData.type?.toLowerCase() as ScoreType) || 'assignment'
              const iconType = SCORE_TYPES.includes(assetType) ? assetType : 'assignment'
              const scoreTypeIcon = scoreTypeIconsRef.current[iconType]

              if (!scoreTypeIcon) return

              const xPosition = xScale.getPixelForValue(index)
              const iconSize = 12
              const yPosition = chartArea.bottom + 20

              ctx.drawImage(scoreTypeIcon, xPosition - iconSize / 2, yPosition, iconSize, iconSize)
            })
          }
        },
      }

      chartRef.current = new ChartJS(canvasRef.current, {
        type: 'line',
        data: {
          labels,
          datasets: [
            {
              label: I18n.t('Score'),
              data,
              borderColor: theme.colors.contrasts.grey125125,
              borderWidth: 1,
              backgroundColor: 'transparent',
              pointBackgroundColor: theme.colors.contrasts.grey125125,
              pointBorderColor: theme.colors.contrasts.grey125125,
              pointRadius: 2,
              pointHoverRadius: 4,
              tension: 0,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: {
            duration: 750,
            easing: 'easeInOutQuart',
          },
          layout: {
            padding: {
              left: 16,
              right: 64,
              top: 4,
              bottom: 8,
            },
          },
          plugins: {
            legend: {
              display: false,
            },
            tooltip: {
              callbacks: {
                label: context => {
                  const score = context.parsed.y
                  const index = context.dataIndex
                  const scoreData = sortedScores[index]
                  return `${scoreData.title}: ${score}`
                },
              },
            },
          },
          scales: {
            y: {
              min: yMin,
              max: yMax,
              afterBuildTicks: axis => {
                // Set explicit ticks at mastery level values only
                axis.ticks = masteryLevelConfigs.map(c => ({value: c.value}))
              },
              ticks: {
                callback: function (value) {
                  // Check if this value corresponds to a mastery level
                  const isLevelValue = masteryLevelConfigs.some(
                    c => Math.abs(c.value - Number(value)) < 0.01,
                  )

                  if (!isLevelValue) {
                    return ''
                  }

                  // Show numbers when useNumbers is true, otherwise hide labels (icons will show)
                  if (useNumbers) {
                    return Math.round(Number(value)).toString()
                  }
                  return ''
                },
                padding: 10,
                autoSkip: false,
              },
              grid: {
                drawBorder: true,
                lineWidth: context => {
                  const tickValue = context.tick?.value
                  if (tickValue == null) return 1

                  // Highlight the mastery level line by comparing to actual mastery point value
                  const isMasteryLine = Math.abs(masteryPointValue - tickValue) < 0.01
                  if (isMasteryLine) {
                    return 2
                  }
                  return 1
                },
                drawTicks: false,
                color: context => {
                  const tickValue = context.tick?.value
                  if (tickValue == null) {
                    return theme.colors.contrasts.grey1214
                  }

                  // Check if this tick corresponds to mastery level by comparing to actual mastery point value
                  const isMasteryLine = Math.abs(masteryPointValue - tickValue) < 0.01
                  if (isMasteryLine) {
                    return theme.colors.contrasts.green4570
                  }

                  // Check if this tick corresponds to any mastery level config
                  const isConfigLevel = masteryLevelConfigs.some(
                    c => Math.abs(c.value - tickValue) < 0.01,
                  )
                  if (!isConfigLevel) {
                    return 'transparent'
                  }

                  return theme.colors.contrasts.grey1214
                },
                borderDash: context => {
                  const tickValue = context.tick?.value
                  if (tickValue == null) return []

                  // Check if this is the mastery line by comparing to actual mastery point value
                  const isMasteryLine = Math.abs(masteryPointValue - tickValue) < 0.01
                  if (isMasteryLine) {
                    return [5, 5]
                  }
                  return []
                },
                borderWidth: 1,
                borderColor: theme.colors.contrasts.grey125125,
              },
              title: {
                display: false,
              },
            },
            x: {
              offset: false,
              ticks: {
                color: theme.colors.contrasts.grey125125,
                font: {
                  family:
                    'LatoWeb, "Lato Extended", Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
                  size: 12,
                },
                padding: 32,
              },
              grid: {
                display: false,
                offset: false,
                borderWidth: 1,
                borderColor: theme.colors.contrasts.grey125125,
              },
              title: {
                display: false,
              },
            },
          },
        },
        plugins: [iconsPlugin],
      })
    })

    return () => {
      chartRef.current?.destroy()
    }
  }, [sortedScores, masteryLevelConfigs, yMin, yMax, masteryPointValue, useNumbers])

  return {canvasRef, sortedScores}
}
