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

import {IssueDataPoint} from '../../types'
import {
  getChartData,
  getChartOptions,
  getSeverityCounts,
  processIssuesToChartData,
} from '../../utils/chart'

jest.mock('@canvas/i18n', () => ({
  useScope: () => ({
    t: (text: string) => text, // mock translation
  }),
}))

const sampleData: IssueDataPoint[] = [
  {id: 'img_alt', issue: 'Image alt text', count: 3, severity: 'High'},
  {id: 'table_caption', issue: 'Table caption', count: 2, severity: 'Medium'},
  {id: 'heading_structure', issue: 'Heading structure', count: 1, severity: 'Low'},
]

describe('processIssuesToChartData', () => {
  const rawData = {
    pages: {
      1: {
        severity: 'medium',
        issues: [
          {ruleId: 'img-alt', displayName: 'Image alt text'},
          {ruleId: 'img-alt', displayName: 'Image alt text'},
        ],
      },
    },
    attachments: {
      2: {
        severity: 'low',
        issues: [
          {ruleId: 'img-alt', displayName: 'Image alt text'},
          {ruleId: 'table-caption', displayName: 'Table caption'},
        ],
      },
      3: {
        severity: 'high',
        issues: [{ruleId: 'img-alt', displayName: 'Image alt text'}],
      },
    },
  }

  const parsedData: IssueDataPoint[] = [
    {
      id: 'img_alt',
      issue: 'Image alt text',
      count: 4,
      severity: 'High', // highest severity among sources
    },
    {
      id: 'table_caption',
      issue: 'Table caption',
      count: 1,
      severity: 'Low',
    },
  ]

  it('returns empty array if input is null', () => {
    const result = processIssuesToChartData(null)
    expect(result).toEqual([])
  })

  it('processes raw data into chart data correctly', () => {
    const result = processIssuesToChartData(rawData)

    expect(result).toEqual(expect.arrayContaining(parsedData))
    expect(result).toHaveLength(2)
  })
})

describe('getChartData', () => {
  it('should assign correct background colors based on severity', () => {
    const result = getChartData(sampleData, 800)
    expect(result.datasets[0].backgroundColor).toEqual([
      '#9B181C', // High
      '#E62429', // Medium
      '#F06E26', // Low
    ])
  })
})

describe('getChartOptions', () => {
  it('sets autoSkip based on containerWidth', () => {
    const wide = getChartOptions(sampleData, 600)
    const narrow = getChartOptions(sampleData, 300)
    expect(wide.scales.x.ticks.autoSkip).toBe(false)
    expect(narrow.scales.x.ticks.autoSkip).toBe(true)
  })
})

describe('getSeverityCounts', () => {
  it('correctly aggregates severity totals', () => {
    const counts = getSeverityCounts(sampleData)
    expect(counts).toEqual({
      high: 3,
      medium: 2,
      low: 1,
    })
  })
})
