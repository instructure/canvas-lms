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

import {mockIssuesSummary1} from '../../../../shared/react/stores/mockData'
import {IssueDataPoint} from '../../../../shared/react/types'
import {getChartData, getChartOptions, getSeverityCounts, processIssuesToChartData} from '../chart'

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

const parsedIssueDataPoints: IssueDataPoint[] = [
  {
    id: 'headings-sequence',
    issue: 'Headings sequence',
    count: 1,
    severity: 'Low',
  },
  {
    id: 'small-text-contrast',
    issue: 'Small text contrast',
    count: 10,
    severity: 'Medium',
  },
  {
    id: 'adjacent-links',
    issue: 'Duplicate links',
    count: 50,
    severity: 'High',
  },
]

describe('processIssuesToChartData', () => {
  it('returns empty array if input is null', () => {
    const result = processIssuesToChartData({})
    expect(result).toEqual([])
  })

  it('processes raw data into chart data correctly', () => {
    const result = processIssuesToChartData(mockIssuesSummary1.byRuleType)

    expect(result).toEqual(expect.arrayContaining(parsedIssueDataPoints))
    expect(result).toHaveLength(3)
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
