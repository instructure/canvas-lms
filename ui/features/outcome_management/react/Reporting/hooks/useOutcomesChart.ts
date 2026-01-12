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

import {useEffect, useRef} from 'react'
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
import type {OutcomeIconType} from '@canvas/outcomes/react/utils/icons'
import {LMGBScoreReporting, ScoreType} from '../types'
import {theme} from '@instructure/canvas-theme'

const I18n = createI18nScope('outcome_management')

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
 * Static mastery level - score configuration should be fixed with following ticket:
 * OUTC-504 (https://instructure.atlassian.net/browse/OUTC-504)
 */
const MASTERY_LEVEL_CONFIGS: Array<{level: OutcomeIconType; value: number}> = [
  {level: 'remediation', value: 1},
  {level: 'near_mastery', value: 2},
  {level: 'mastery', value: 3},
  {level: 'exceeds_mastery', value: 4},
] as const

const MASTERY_LEVEL_MASTERY_INDEX = MASTERY_LEVEL_CONFIGS.length - 1

const SCORE_TYPES: ScoreType[] = ['quiz', 'discussion', 'assignment'] as const

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

export const useOutcomesChart = (scores: LMGBScoreReporting[]) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const chartRef = useRef<ChartJS<'line'> | null>(null)
  const masteryIconsRef = useRef<{[key: string]: HTMLImageElement}>({})
  const scoreTypeIconsRef = useRef<{[key: string]: HTMLImageElement}>({})

  // Show 5 latest scores
  const sortedScores = [...scores]
    .sort((a, b) => new Date(a.submitted_at).getTime() - new Date(b.submitted_at).getTime())
    .slice(-5)

  useEffect(() => {
    if (!canvasRef.current || sortedScores.length === 0) return

    const loadMasteryIcons = loadIcons(MASTERY_LEVEL_CONFIGS, masteryIconsRef, ({level}) => level)
    const loadScoreTypeIcons = loadIcons(SCORE_TYPES, scoreTypeIconsRef, type => type)

    Promise.all([...loadMasteryIcons, ...loadScoreTypeIcons]).then(() => {
      if (!canvasRef.current) return

      const labels = sortedScores.map(score => {
        const date = new Date(score.submitted_at)
        return date.toLocaleDateString(I18n.currentLocale(), {month: 'numeric', day: 'numeric'})
      })

      const data = sortedScores.map(score => score.score)

      chartRef.current?.destroy()

      // Custom plugin to draw icons on Y-axis and X-axis
      const iconsPlugin = {
        id: 'icons',
        afterDraw: (chart: ChartJS) => {
          const ctx = chart.ctx
          const yScale = chart.scales.y
          const xScale = chart.scales.x
          const chartArea = chart.chartArea

          // Draw Y-axis icons
          MASTERY_LEVEL_CONFIGS.forEach(({level, value}) => {
            const icon = masteryIconsRef.current[level]
            if (!icon) return

            const yPosition = yScale.getPixelForValue(value)
            const iconSize = 12
            const xPosition = chartArea.left - iconSize - 14

            ctx.drawImage(icon, xPosition, yPosition - iconSize / 2, iconSize, iconSize)
          })

          if (xScale.ticks) {
            // Draw X-axis icons
            xScale.ticks.forEach((_tick, index) => {
              const scoreTypeIcon = scoreTypeIconsRef.current['quiz']

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
              min: 0,
              max: 4.5,
              ticks: {
                stepSize: 1,
                callback: function () {
                  return ''
                },
                padding: 10,
              },
              grid: {
                drawBorder: true,
                lineWidth: context => {
                  if (context.tick?.value === MASTERY_LEVEL_MASTERY_INDEX) {
                    return 2
                  }
                  return 1
                },
                drawTicks: false,
                color: context => {
                  if (context.tick?.value > MASTERY_LEVEL_CONFIGS.length) {
                    return 'transparent'
                  }
                  if (context.tick?.value === MASTERY_LEVEL_MASTERY_INDEX) {
                    return theme.colors.contrasts.green4570
                  }
                  return theme.colors.contrasts.grey1214
                },
                borderDash: context => {
                  if (context.tick?.value === MASTERY_LEVEL_MASTERY_INDEX) {
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
  }, [sortedScores])

  return {canvasRef, sortedScores}
}
