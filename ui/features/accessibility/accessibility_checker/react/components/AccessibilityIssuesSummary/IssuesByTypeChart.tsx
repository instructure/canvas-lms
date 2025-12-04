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
import {Flex} from '@instructure/ui-flex'
import {useAccessibilityScansStore} from '../../../../shared/react/stores/AccessibilityScansStore'
import {IssueDataPoint} from '../../../../shared/react/types'
import {getChartData, getChartOptions, processIssuesToChartData} from '../../utils/chart'

const I18n = createI18nScope('issuesByTypeChart')

ChartJS.register(BarController, CategoryScale, LinearScale, BarElement, Title, Tooltip)

function renderLoading() {
  return (
    <View as="div" width="100%" textAlign="center" height="250px">
      <Spinner renderTitle={I18n.t('Loading accessibility issues')} size="large" margin="auto" />
    </View>
  )
}

interface IssuesByTypeChartProps {
  isMobile?: boolean
}

export const IssuesByTypeChart: React.FC<IssuesByTypeChartProps> = ({isMobile}) => {
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
    () => getChartData(issuesData, containerWidth, isMobile ? 3 : 6),
    [issuesData, containerWidth, isMobile],
  )

  const chartOptions = useMemo(
    () => getChartOptions(issuesData, containerWidth),
    [issuesData, containerWidth],
  )

  const chartScreenReaderDescription = useMemo(() => {
    // unable to dynamically declare and interpolate i18n strings for bar chart columns
    // workaround is to declare single and plural template with dummy interpolation
    // then replace dummy values with actual values during render

    const issueTemplateSingle = I18n.t('%{count} issue for %{category}', {
      count: 0,
      category: 'PLACEHOLDER',
    })

    const issueTemplatePlural = I18n.t('%{count} issues for %{category}', {
      count: 0,
      category: 'PLACEHOLDER',
    })

    return issuesData.length > 0 ? (
      <span>
        {I18n.t('Chart data: ')}
        {issuesData.map(item => {
          const template = item.count === 1 ? issueTemplateSingle : issueTemplatePlural
          return template
            .toString()
            .replace('0', item.count.toString())
            .replace('PLACEHOLDER', item.issue)
            .concat(', ')
        })}
      </span>
    ) : (
      I18n.t('No accessibility issues found.')
    )
  }, [issuesData])

  const ariaLabel = I18n.t(
    {
      one: 'Accessibility issues bar chart showing %{count} issue.',
      other: 'Accessibility issues bar chart showing %{count} issues.',
    },
    {
      count: issuesData.reduce((acc, item) => acc + item.count, 0),
    },
  )

  useEffect(() => {
    if (canvasRef.current) {
      // Destroy existing chart to prevent duplicates
      chartRef.current?.destroy()
      chartRef.current = new ChartJS(canvasRef.current, {
        type: 'bar',
        data: chartData,
        options: {
          ...chartOptions,
          indexAxis: isMobile ? 'y' : 'x',
        },
      })
    }
  }, [chartData, chartOptions, isMobile])

  // Cleanup chart on unmount
  useEffect(() => {
    return () => {
      chartRef.current?.destroy()
    }
  }, [])

  if (loadingOfSummary) return renderLoading()

  const chartHeight = isMobile ? Math.max(190, Math.floor(chartData.labels.length * 75)) : 190

  return (
    <Flex
      as="div"
      gap="small"
      padding="small"
      direction="column"
      alignItems="center"
      justifyItems="center"
    >
      <Heading level="h3" variant="titleCardRegular">
        {I18n.t('Issues by type')}
      </Heading>
      <Flex.Item
        as="div"
        width="100%"
        height={`${chartHeight}px`}
        elementRef={r => {
          if (r instanceof HTMLDivElement || r === null) {
            containerRef.current = r
          }
        }}
      >
        <canvas
          role="img"
          ref={canvasRef}
          aria-label={ariaLabel}
          aria-describedby="chart-description"
          data-testid="issues-by-type-chart"
        />
        <div
          className="sr-only"
          id="chart-description"
          style={{visibility: 'hidden', overflow: 'hidden', height: 0}}
        >
          {chartScreenReaderDescription}
        </div>
      </Flex.Item>
    </Flex>
  )
}
