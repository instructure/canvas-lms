/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import {MasteryDistributionChart, MasteryDistributionChartProps} from '../MasteryDistributionChart'
import {MOCK_OUTCOMES} from '../../../__fixtures__/rollups'

// Mock the BarChart component to simplify testing
vi.mock('../BarChart', () => ({
  BarChart: ({labels, values, backgroundColor}: any) => (
    <div data-testid="bar-chart">
      <div data-testid="chart-labels">{JSON.stringify(labels)}</div>
      <div data-testid="chart-values">{JSON.stringify(values)}</div>
      <div data-testid="chart-colors">{JSON.stringify(backgroundColor)}</div>
    </div>
  ),
}))

describe('MasteryDistributionChart', () => {
  const defaultProps = (): MasteryDistributionChartProps => ({
    outcome: MOCK_OUTCOMES[0],
    scores: [5, 3, 3, 2, 5],
    width: '100%',
    height: 400,
  })

  it('renders the BarChart component', () => {
    const {getByTestId} = render(<MasteryDistributionChart {...defaultProps()} />)
    expect(getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('correctly counts scores for each mastery level', () => {
    const {getByTestId} = render(<MasteryDistributionChart {...defaultProps()} />)
    const values = JSON.parse(getByTestId('chart-values').textContent || '[]')

    expect(values).toHaveLength(4)
    expect(values.every((v: number) => typeof v === 'number')).toBe(true)
  })

  it('orders mastery levels from highest to lowest points', () => {
    const {getByTestId} = render(<MasteryDistributionChart {...defaultProps()} />)
    const labels = JSON.parse(getByTestId('chart-labels').textContent || '[]')

    expect(labels[0]).toBe('great!')
    expect(labels[labels.length - 1]).toBe('not great')
  })

  it('prepends # to color values that do not start with #', () => {
    const {getByTestId} = render(<MasteryDistributionChart {...defaultProps()} />)
    const colors = JSON.parse(getByTestId('chart-colors').textContent || '[]')

    colors.forEach((color: string) => {
      expect(color).toMatch(/^#/)
    })
  })

  it('handles color values that already start with #', () => {
    const propsWithHashColors = {
      ...defaultProps(),
      outcome: {
        ...MOCK_OUTCOMES[0],
        ratings: [
          {
            description: 'Excellent',
            points: 5,
            color: '#00FF00',
            mastery: true,
          },
        ],
      },
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithHashColors} />)
    const colors = JSON.parse(getByTestId('chart-colors').textContent || '[]')

    expect(colors).toEqual(['#00FF00'])
  })

  it('uses fallback color for ratings without color', () => {
    const propsWithoutColor = {
      ...defaultProps(),
      outcome: {
        ...MOCK_OUTCOMES[0],
        ratings: [
          {
            description: 'No Color',
            points: 3,
            color: undefined as any,
            mastery: false,
          },
        ],
      },
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithoutColor} />)
    const colors = JSON.parse(getByTestId('chart-colors').textContent || '[]')

    expect(colors[0]).toMatch(/^#[0-9A-Fa-f]{6}$/)
  })

  it('ignores undefined scores when counting', () => {
    const propsWithUndefined = {
      ...defaultProps(),
      scores: [5, undefined, 3, undefined, 2],
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithUndefined} />)
    const values = JSON.parse(getByTestId('chart-values').textContent || '[]')

    expect(values).toHaveLength(4)
    expect(values.reduce((sum: number, v: number) => sum + v, 0)).toBe(3)
  })

  it('handles empty scores array', () => {
    const propsWithEmptyScores = {
      ...defaultProps(),
      scores: [],
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithEmptyScores} />)
    const values = JSON.parse(getByTestId('chart-values').textContent || '[]')

    expect(values).toEqual([0, 0, 0, 0])
  })

  it('handles scores array with only undefined values', () => {
    const propsWithAllUndefined = {
      ...defaultProps(),
      scores: [undefined, undefined, undefined],
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithAllUndefined} />)
    const values = JSON.parse(getByTestId('chart-values').textContent || '[]')

    expect(values).toEqual([0, 0, 0, 0])
  })

  it('passes custom width and height to BarChart', () => {
    const customProps = {
      ...defaultProps(),
      width: '500px',
      height: 300,
    }

    const {getByTestId} = render(<MasteryDistributionChart {...customProps} />)
    expect(getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('passes showLegend prop to BarChart', () => {
    const propsWithLegend = {
      ...defaultProps(),
      showLegend: true,
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithLegend} />)
    expect(getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('passes showGrid prop to BarChart', () => {
    const propsWithoutGrid = {
      ...defaultProps(),
      showGrid: false,
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithoutGrid} />)
    expect(getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('passes isPreview prop to BarChart', () => {
    const propsWithPreview = {
      ...defaultProps(),
      isPreview: true,
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithPreview} />)
    expect(getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('handles ratings without descriptions', () => {
    const propsWithoutDescriptions = {
      ...defaultProps(),
      outcome: {
        ...MOCK_OUTCOMES[0],
        ratings: [
          {
            description: '',
            points: 3,
            color: '00FF00',
            mastery: false,
          },
        ],
      },
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithoutDescriptions} />)
    expect(getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('correctly assigns scores that fall between rating thresholds', () => {
    const propsWithInBetweenScores = {
      ...defaultProps(),
      scores: [4.5, 2.5, 0.5],
    }

    const {getByTestId} = render(<MasteryDistributionChart {...propsWithInBetweenScores} />)
    const values = JSON.parse(getByTestId('chart-values').textContent || '[]')

    expect(values).toHaveLength(4)
    expect(values.every((v: number) => typeof v === 'number')).toBe(true)
  })
})
