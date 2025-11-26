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

import {useScope as createI18nScope} from '@canvas/i18n'

import {FILTER_GROUP_MAPPING, issueTypeOptions} from '../constants'
import {IssueDataPoint, IssueRuleType, FilterGroupMapping} from '../../../shared/react/types'
import {getIssueSeverity} from '../../../shared/react/utils/apiData'
import {primitives} from '@instructure/ui-themes'

const I18n = createI18nScope('accessibility_checker')

export const getGroupedFilterForRuleType = (ruleType: IssueRuleType): string | null => {
  const groupedFilters = Object.keys(FILTER_GROUP_MAPPING) as Array<keyof FilterGroupMapping>

  return (
    groupedFilters.find(groupedFilter => FILTER_GROUP_MAPPING[groupedFilter].includes(ruleType)) ||
    null
  )
}

export const processIssuesToChartData = (byRuleType?: Record<string, number>): IssueDataPoint[] => {
  if (!byRuleType || typeof byRuleType !== 'object') {
    return []
  }

  const dataPoints: Record<string, IssueDataPoint> = {}

  Object.entries(byRuleType).forEach(([ruleType, count]: [string, number]) => {
    const groupedFilter = getGroupedFilterForRuleType(ruleType as IssueRuleType)
    const displayId = groupedFilter || ruleType
    const displayLabel =
      issueTypeOptions.find(option => option.value === displayId)?.label || displayId

    if (dataPoints[displayId]) {
      dataPoints[displayId].count += count
      dataPoints[displayId].severity = getIssueSeverity(dataPoints[displayId].count)
    } else {
      dataPoints[displayId] = {
        id: displayId,
        count,
        issue: displayLabel,
        severity: getIssueSeverity(count),
      }
    }
  })

  return Object.values(dataPoints)
}

const wrapLabel = (label: string, maxWidth: number = 70, avgCharWidth = 6): string[] => {
  const words = label.split(' ')
  const lines: string[] = []
  const charsPerLine = Math.floor(maxWidth / avgCharWidth)
  let currentLine = ''

  words.forEach(word => {
    const testLine = currentLine ? `${currentLine} ${word}` : word

    if (testLine.length <= charsPerLine) {
      currentLine = testLine
    } else {
      if (currentLine) lines.push(currentLine)
      currentLine = word
    }
  })

  if (currentLine) lines.push(currentLine)

  return lines
}

export const getChartData = (
  issuesData: IssueDataPoint[],
  containerWidth: number,
  avgCharWidth: number,
) => {
  const barWidth = (containerWidth / issuesData.length) * 0.8 * 0.9 // 80% for bars, 90% for padding
  const datasetData = issuesData.map(d => d.count)
  const labels = issuesData.map(d => {
    const labelWithCount = `${d.issue} (${d.count})`
    return wrapLabel(labelWithCount, barWidth, avgCharWidth)
  })

  return {
    labels,
    datasets: [
      {
        label: I18n.t('Issues'),
        data: datasetData,
        backgroundColor: primitives.red45,
        borderRadius: 4,
      },
    ],
  }
}

export const getChartOptions = (issuesData: IssueDataPoint[], containerWidth: number) => {
  const tooltips = issuesData.map(d => d.issue)
  const datasetData = issuesData.map(d => d.count)

  const maxCount = Math.max(...datasetData, 1)

  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {display: false},
      tooltip: {
        enabled: true,
        callbacks: {
          title: function (tooltipItems: {dataIndex: any}[]) {
            const index = tooltipItems[0].dataIndex
            return tooltips[index]
          },
        },
      },
      title: {display: false},
    },
    layout: {padding: 0},
    scales: {
      y: {
        beginAtZero: true,
        suggestedMax: maxCount + 2,
        ticks: {precision: 0, stepSize: 1},
        grid: {display: false, drawBorder: false},
      },
      x: {
        ticks: {
          maxRotation: 0,
          minRotation: 0,
          autoSkip: containerWidth > 440 ? false : true,
        },
        grid: {display: false, drawBorder: false},
      },
    },
  }
}

export function getSeverityCounts(issuesData: IssueDataPoint[]) {
  return {
    high: issuesData.filter(d => d.severity === 'High').reduce((sum, d) => sum + d.count, 0),
    medium: issuesData.filter(d => d.severity === 'Medium').reduce((sum, d) => sum + d.count, 0),
    low: issuesData.filter(d => d.severity === 'Low').reduce((sum, d) => sum + d.count, 0),
  }
}
