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

import React, {useEffect, useMemo, useRef, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Chart as ChartJS, BarElement, CategoryScale, LinearScale, Tooltip, Title} from 'chart.js'
import {Bar} from 'react-chartjs-2'
import {ruleIdToLabelMap} from '../../constants'
import {
  getChartData,
  getChartOptions,
  getSeverityCounts,
  processIssuesToChartData,
} from '../../utils'
import {AccessibilityData, IssueDataPoint} from '../../types'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('issuesByTypeChart')

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip)

type IssuesByTypeChartProps = {
  accessibilityIssues: AccessibilityData | null
  isLoading?: boolean
}

function renderLoading() {
  return (
    <View as="div" width="100%" textAlign="center">
      <Spinner renderTitle={I18n.t('Loading accessibility issues')} size="large" margin="auto" />
    </View>
  )
}

Object.defineProperty(window, 'ResizeObserver', {
  writable: true,
  configurable: true,
  value: ResizeObserver as any,
})

export const IssuesByTypeChart: React.FC<IssuesByTypeChartProps> = ({
  accessibilityIssues,
  isLoading,
}: IssuesByTypeChartProps) => {
  const containerRef = useRef<HTMLDivElement | null>(null)
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
  }, [isLoading])

  const issuesData: IssueDataPoint[] = useMemo(
    () => processIssuesToChartData(accessibilityIssues, ruleIdToLabelMap),
    [accessibilityIssues, ruleIdToLabelMap],
  )
  const severityCounts = useMemo(() => getSeverityCounts(issuesData), [issuesData])

  const chartData = getChartData(issuesData, containerWidth)
  const chartOptions = getChartOptions(issuesData, containerWidth)

  const ariaLabel = I18n.t(
    'Issues by type chart. High: %{high} issues, Medium: %{medium} issues, Low: %{low} issues.',
    {high: severityCounts.high, medium: severityCounts.medium, low: severityCounts.low},
  )

  if (isLoading) return renderLoading()

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
        <Bar data={chartData} options={chartOptions} />
      </View>
    </View>
  )
}
