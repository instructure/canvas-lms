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

import {useEffect, useMemo, useRef, useState} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {
  Chart as ChartJS,
  BarController,
  BarElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Title,
} from 'chart.js'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {useAccessibilityScansStore} from '../../../../shared/react/stores/AccessibilityScansStore'
import {IssueDataPoint} from '../../../../shared/react/types'
import {
  getChartData,
  getChartOptions,
  getSeverityCounts,
  processIssuesToChartData,
} from '../../utils/chart'

const I18n = createI18nScope('issuesByTypeChart')

ChartJS.register(BarController, CategoryScale, LinearScale, BarElement, Title, Tooltip)

function renderLoading() {
  return (
    <View as="div" width="100%" textAlign="center" height="250px">
      <Spinner renderTitle={I18n.t('Loading accessibility issues')} size="large" margin="auto" />
    </View>
  )
}

export const IssuesByTypeChart = () => {
  const [issuesSummary, loadingOfSummary] = useAccessibilityScansStore(
    useShallow(state => [state.issuesSummary, state.loadingOfSummary]),
  )

  const containerRef = useRef<HTMLDivElement | null>(null)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const chartRef = useRef<ChartJS<'bar'> | null>(null)
  const [containerWidth, setContainerWidth] = useState<number>(0)

  useEffect(() => {
    const element = containerRef.current
    if (!element) return
    const observer = new ResizeObserver(entries => {
      for (const entry of entries) {
        if (entry.contentRect) {
          setContainerWidth(entry.contentRect.width)
        }
      }
    })
    observer.observe(element as Element)
    return () => observer.disconnect()
  }, [loadingOfSummary])

  const issuesData: IssueDataPoint[] = useMemo(
    () => processIssuesToChartData(issuesSummary?.byRuleType),
    [issuesSummary],
  )
  const chartData = useMemo(
    () => getChartData(issuesData, containerWidth),
    [issuesData, containerWidth],
  )
  const chartOptions = useMemo(
    () => getChartOptions(issuesData, containerWidth),
    [issuesData, containerWidth],
  )

  const severityCounts = useMemo(() => getSeverityCounts(issuesData), [issuesData])

  const ariaLabel = I18n.t(
    'Issues by type chart. High: %{high} issues, Medium: %{medium} issues, Low: %{low} issues.',
    {high: severityCounts.high, medium: severityCounts.medium, low: severityCounts.low},
  )

  useEffect(() => {
    if (canvasRef.current) {
      // Destroy existing chart to prevent duplicates
      chartRef.current?.destroy()
      chartRef.current = new ChartJS(canvasRef.current, {
        type: 'bar',
        data: chartData,
        options: chartOptions,
      })
    }
  }, [chartData, chartOptions])

  // Cleanup chart on unmount
  useEffect(() => {
    return () => {
      chartRef.current?.destroy()
    }
  }, [])

  if (loadingOfSummary) return renderLoading()

  return (
    <View as="div" height="250px">
      <Heading level="h3" margin="0 0 medium 0">
        {I18n.t('Issues by type')}
      </Heading>
      <View
        as="div"
        data-testid="issues-by-type-chart"
        aria-label={ariaLabel}
        elementRef={r => {
          if (r instanceof HTMLDivElement || r === null) {
            containerRef.current = r
          }
        }}
        height="190px"
      >
        <canvas ref={canvasRef} />
      </View>
    </View>
  )
}
