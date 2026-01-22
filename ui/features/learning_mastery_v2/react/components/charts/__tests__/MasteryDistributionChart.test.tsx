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

import {render, screen} from '@testing-library/react'
import {MasteryDistributionChart, MasteryDistributionChartProps} from '../MasteryDistributionChart'
import {MOCK_OUTCOMES} from '../../../__fixtures__/rollups'
import {RatingDistribution} from '@canvas/outcomes/react/types/mastery_distribution'

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
  const defaultDistributionData = (): RatingDistribution[] => [
    {
      description: 'great!',
      points: 5,
      color: 'blue',
      count: 2,
      student_ids: ['1', '5'],
    },
    {
      description: 'mastery!',
      points: 3,
      color: 'green',
      count: 2,
      student_ids: ['2', '3'],
    },
    {
      description: 'rating description!',
      points: 2,
      color: 'yellow',
      count: 1,
      student_ids: ['4'],
    },
    {
      description: 'not great',
      points: 0,
      color: 'red',
      count: 0,
      student_ids: [],
    },
  ]

  const defaultProps = (): MasteryDistributionChartProps => ({
    outcome: MOCK_OUTCOMES[0],
    distributionData: defaultDistributionData(),
    width: '100%',
    height: 400,
  })

  it('renders the BarChart component', () => {
    render(<MasteryDistributionChart {...defaultProps()} />)
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('correctly displays counts for each mastery level', () => {
    render(<MasteryDistributionChart {...defaultProps()} />)
    const values = JSON.parse(screen.getByTestId('chart-values').textContent || '[]')

    expect(values).toHaveLength(4)
    expect(values).toEqual([2, 2, 1, 0])
  })

  it('displays mastery levels in the order provided', () => {
    render(<MasteryDistributionChart {...defaultProps()} />)
    const labels = JSON.parse(screen.getByTestId('chart-labels').textContent || '[]')

    expect(labels[0]).toBe('great!')
    expect(labels[1]).toBe('mastery!')
    expect(labels[2]).toBe('rating description!')
    expect(labels[3]).toBe('not great')
  })

  it('prepends # to color values that do not start with #', () => {
    render(<MasteryDistributionChart {...defaultProps()} />)
    const colors = JSON.parse(screen.getByTestId('chart-colors').textContent || '[]')

    colors.forEach((color: string) => {
      expect(color).toMatch(/^#/)
    })
  })

  it('handles color values that already start with #', () => {
    const propsWithHashColors = {
      ...defaultProps(),
      distributionData: [
        {
          description: 'Excellent',
          points: 5,
          color: '#00FF00',
          count: 3,
          student_ids: ['1', '2', '3'],
        },
      ],
    }

    render(<MasteryDistributionChart {...propsWithHashColors} />)
    const colors = JSON.parse(screen.getByTestId('chart-colors').textContent || '[]')

    expect(colors).toEqual(['#00FF00'])
  })

  it('uses fallback color for ratings without color in empty distributionData', () => {
    const propsWithoutColor = {
      ...defaultProps(),
      distributionData: [],
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

    render(<MasteryDistributionChart {...propsWithoutColor} />)
    const colors = JSON.parse(screen.getByTestId('chart-colors').textContent || '[]')

    expect(colors[0]).toMatch(/^#[0-9A-Fa-f]{6}$/)
  })

  it('displays counts from distributionData', () => {
    const propsWithCounts = {
      ...defaultProps(),
      distributionData: [
        {
          description: 'Level 1',
          points: 5,
          color: 'blue',
          count: 5,
          student_ids: ['1', '2', '3', '4', '5'],
        },
        {
          description: 'Level 2',
          points: 3,
          color: 'green',
          count: 3,
          student_ids: ['6', '7', '8'],
        },
        {
          description: 'Level 3',
          points: 0,
          color: 'red',
          count: 2,
          student_ids: ['9', '10'],
        },
      ],
    }

    render(<MasteryDistributionChart {...propsWithCounts} />)
    const values = JSON.parse(screen.getByTestId('chart-values').textContent || '[]')

    expect(values).toHaveLength(3)
    expect(values).toEqual([5, 3, 2])
  })

  it('handles empty distributionData by using outcome ratings', () => {
    const propsWithEmptyData = {
      ...defaultProps(),
      distributionData: [],
    }

    render(<MasteryDistributionChart {...propsWithEmptyData} />)
    const values = JSON.parse(screen.getByTestId('chart-values').textContent || '[]')
    const labels = JSON.parse(screen.getByTestId('chart-labels').textContent || '[]')

    // Should create entries from outcome.ratings with 0 counts
    expect(values).toEqual([0, 0, 0, 0])
    expect(labels).toHaveLength(4)
  })

  it('handles distributionData with zero counts', () => {
    const propsWithZeroCounts = {
      ...defaultProps(),
      distributionData: [
        {
          description: 'Level 1',
          points: 5,
          color: 'blue',
          count: 0,
          student_ids: [],
        },
        {
          description: 'Level 2',
          points: 3,
          color: 'green',
          count: 0,
          student_ids: [],
        },
      ],
    }

    render(<MasteryDistributionChart {...propsWithZeroCounts} />)
    const values = JSON.parse(screen.getByTestId('chart-values').textContent || '[]')

    expect(values).toEqual([0, 0])
  })

  it('passes custom width and height to BarChart', () => {
    const customProps = {
      ...defaultProps(),
      width: '500px',
      height: 300,
    }

    render(<MasteryDistributionChart {...customProps} />)
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('passes showLegend prop to BarChart', () => {
    const propsWithLegend = {
      ...defaultProps(),
      showLegend: true,
    }

    render(<MasteryDistributionChart {...propsWithLegend} />)
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('passes showXAxisGrid prop to BarChart', () => {
    const propsWithoutGrid = {
      ...defaultProps(),
      showXAxisGrid: false,
    }

    render(<MasteryDistributionChart {...propsWithoutGrid} />)
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('passes showYAxisGrid prop to BarChart', () => {
    const propsWithoutGrid = {
      ...defaultProps(),
      showYAxisGrid: false,
    }

    render(<MasteryDistributionChart {...propsWithoutGrid} />)
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('passes isPreview prop to BarChart', () => {
    const propsWithPreview = {
      ...defaultProps(),
      isPreview: true,
    }

    render(<MasteryDistributionChart {...propsWithPreview} />)
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
  })

  it('handles ratings without descriptions by falling back to points', () => {
    const propsWithoutDescriptions = {
      ...defaultProps(),
      distributionData: [],
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

    render(<MasteryDistributionChart {...propsWithoutDescriptions} />)
    const labels = JSON.parse(screen.getByTestId('chart-labels').textContent || '[]')

    expect(labels[0]).toBe('3 pts')
  })

  it('handles various rating point values', () => {
    const propsWithVariousPoints = {
      ...defaultProps(),
      distributionData: [
        {
          description: 'High',
          points: 4.5,
          color: 'blue',
          count: 1,
          student_ids: ['1'],
        },
        {
          description: 'Medium',
          points: 2.5,
          color: 'yellow',
          count: 1,
          student_ids: ['2'],
        },
        {
          description: 'Low',
          points: 0.5,
          color: 'red',
          count: 1,
          student_ids: ['3'],
        },
      ],
    }

    render(<MasteryDistributionChart {...propsWithVariousPoints} />)
    const values = JSON.parse(screen.getByTestId('chart-values').textContent || '[]')

    expect(values).toHaveLength(3)
    expect(values).toEqual([1, 1, 1])
  })
})
