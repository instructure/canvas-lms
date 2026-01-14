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
import {
  getChartData,
  getChartOptions,
  getGroupedFilterForRuleType,
  getSeverityCounts,
  processIssuesToChartData,
} from '../chart'

vi.mock('@canvas/i18n', () => ({
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
    id: 'heading-order',
    issue: 'Heading order',
    count: 1,
    severity: 'Low',
  },
  {
    id: 'text-contrast',
    issue: 'Text contrast',
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

describe('getGroupedFilterForRuleType', () => {
  it('returns "alt-text" for img-alt rule type', () => {
    expect(getGroupedFilterForRuleType('img-alt')).toBe('alt-text')
  })

  it('returns "alt-text" for img-alt-filename rule type', () => {
    expect(getGroupedFilterForRuleType('img-alt-filename')).toBe('alt-text')
  })

  it('returns "alt-text" for img-alt-length rule type', () => {
    expect(getGroupedFilterForRuleType('img-alt-length')).toBe('alt-text')
  })

  it('returns "heading-order" for headings-sequence rule type', () => {
    expect(getGroupedFilterForRuleType('headings-sequence')).toBe('heading-order')
  })

  it('returns "heading-order" for headings-start-at-h2 rule type', () => {
    expect(getGroupedFilterForRuleType('headings-start-at-h2')).toBe('heading-order')
  })

  it('returns "text-contrast" for large-text-contrast rule type', () => {
    expect(getGroupedFilterForRuleType('large-text-contrast')).toBe('text-contrast')
  })

  it('returns "text-contrast" for small-text-contrast rule type', () => {
    expect(getGroupedFilterForRuleType('small-text-contrast')).toBe('text-contrast')
  })

  it('returns null for rule types not in any group', () => {
    expect(getGroupedFilterForRuleType('adjacent-links')).toBe(null)
  })
})

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
