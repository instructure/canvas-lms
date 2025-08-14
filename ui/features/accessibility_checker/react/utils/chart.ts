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

import {severityColors} from '../constants'
import {IssueDataPoint, RawData, Severity} from '../types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

export function processIssuesToChartData(raw: RawData | null): IssueDataPoint[] {
  if (!raw || typeof raw !== 'object') {
    return []
  }

  const grouped: Record<string, {count: number; displayName: string; severity: Severity}> = {}

  const rootSeverityMap: Record<string, Severity> = {
    low: 'Low',
    medium: 'Medium',
    high: 'High',
  }

  Object.values(raw).forEach((category: any) => {
    Object.values(category).forEach((item: any) => {
      const itemRootSeverity = rootSeverityMap[item.severity?.toLowerCase()] || 'Low'
      const issues = item.issues || []

      issues.forEach((issue: any) => {
        const ruleId = issue.ruleId

        if (!grouped[ruleId]) {
          grouped[ruleId] = {
            count: 1,
            severity: itemRootSeverity,
            displayName: issue.displayName,
          }
        } else {
          grouped[ruleId].count += 1
          grouped[ruleId].severity = prioritizeSeverity(grouped[ruleId].severity, itemRootSeverity)
        }
      })
    })
  })

  return Object.entries(grouped).map(([ruleId, data]) => ({
    id: ruleId.replace(/-/g, '_'),
    issue: data.displayName,
    count: data.count,
    severity: data.severity,
  }))
}

function prioritizeSeverity(a: Severity, b: Severity): Severity {
  const order = {High: 3, Medium: 2, Low: 1}
  return order[a] >= order[b] ? a : b
}

const wrapLabel = (label: string): string[] => label.split(' ')

export function getChartData(issuesData: IssueDataPoint[], containerWidth: number) {
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

export function getChartOptions(issuesData: IssueDataPoint[], containerWidth: number) {
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
