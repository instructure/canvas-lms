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

import {FILTER_GROUP_MAPPING, issueTypeOptions, severityColors} from '../constants'
import {IssueDataPoint, IssueRuleType, FilterGroupMapping} from '../../../shared/react/types'
import {getIssueSeverity} from '../../../shared/react/utils/apiData'

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

const wrapLabel = (label: string): string[] => label.split(' ')

export const getChartData = (issuesData: IssueDataPoint[], containerWidth: number) => {
  // Adaptive labels depending on container size
  const datasetData = issuesData.map(d => d.count)
  const labels = issuesData.map(d => {
    if (containerWidth > 600) {
      return wrapLabel(d.issue) // multi-line labels
    } else {
      const maxLength = 5
      return d.issue.length > maxLength ? d.issue.substring(0, maxLength) + '…' : d.issue
    }
  })

  const barColors = issuesData.map(d => severityColors[d.severity])

  return {
    labels,
    datasets: [
      {
        label: I18n.t('Issues'),
        data: datasetData,
        backgroundColor: barColors,
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
