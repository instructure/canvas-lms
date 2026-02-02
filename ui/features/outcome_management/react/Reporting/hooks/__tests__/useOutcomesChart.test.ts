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

import {describe, it, expect, vi, beforeEach} from 'vitest'
import {renderHook} from '@testing-library/react-hooks'
import {useOutcomesChart} from '../useOutcomesChart'
import type {LMGBScoreReporting} from '../../types'

// Mock the context hook
vi.mock('@canvas/outcomes/react/hooks/useLMGBContext', () => ({
  default: vi.fn(() => ({
    outcomeProficiency: {
      ratings: [
        {points: 9, color: '#0000ff', description: 'Distinguished'},
        {points: 7, color: '#00ff00', description: 'Proficient', mastery: true},
        {points: 5, color: '#ffff00', description: 'Nearly Proficient'},
        {points: 3, color: '#ffa500', description: 'Developing'},
        {points: 0, color: '#ff0000', description: 'Beginning'},
      ],
    },
  })),
}))

describe('useOutcomesChart', () => {
  const mockScores: LMGBScoreReporting[] = [
    {
      score: 7,
      title: 'Assignment 1',
      type: 'assignment',
      submitted_at: '2025-01-01T10:00:00Z',
      links: {outcome: '1'},
    },
    {
      score: 5,
      title: 'Quiz 1',
      type: 'quiz',
      submitted_at: '2025-01-02T10:00:00Z',
      links: {outcome: '1'},
    },
    {
      score: 9,
      title: 'Discussion 1',
      type: 'discussion',
      submitted_at: '2025-01-03T10:00:00Z',
      links: {outcome: '1'},
    },
  ]

  beforeEach(() => {
    // Mock canvas element methods
    HTMLCanvasElement.prototype.getContext = vi.fn(() => ({
      clearRect: vi.fn(),
      fillRect: vi.fn(),
      drawImage: vi.fn(),
      save: vi.fn(),
      restore: vi.fn(),
      beginPath: vi.fn(),
      moveTo: vi.fn(),
      lineTo: vi.fn(),
      stroke: vi.fn(),
      fill: vi.fn(),
      arc: vi.fn(),
    })) as any
  })

  it('returns canvasRef and sortedScores', () => {
    const {result} = renderHook(() => useOutcomesChart(mockScores))

    expect(result.current.canvasRef).toBeDefined()
    expect(result.current.sortedScores).toHaveLength(3)
  })

  it('sorts scores by submission date', () => {
    const {result} = renderHook(() => useOutcomesChart(mockScores))

    expect(result.current.sortedScores[0].title).toBe('Assignment 1')
    expect(result.current.sortedScores[1].title).toBe('Quiz 1')
    expect(result.current.sortedScores[2].title).toBe('Discussion 1')
  })

  it('limits to 5 latest scores', () => {
    const manyScores: LMGBScoreReporting[] = [
      ...mockScores,
      {
        score: 3,
        title: 'Assignment 2',
        type: 'assignment',
        submitted_at: '2025-01-04T10:00:00Z',
        links: {outcome: '1'},
      },
      {
        score: 7,
        title: 'Assignment 3',
        type: 'assignment',
        submitted_at: '2025-01-05T10:00:00Z',
        links: {outcome: '1'},
      },
      {
        score: 9,
        title: 'Assignment 4',
        type: 'assignment',
        submitted_at: '2025-01-06T10:00:00Z',
        links: {outcome: '1'},
      },
    ]

    const {result} = renderHook(() => useOutcomesChart(manyScores))

    expect(result.current.sortedScores).toHaveLength(5)
    expect(result.current.sortedScores[0].title).toBe('Quiz 1')
    expect(result.current.sortedScores[4].title).toBe('Assignment 4')
  })

  it('handles empty scores array', () => {
    const {result} = renderHook(() => useOutcomesChart([]))

    expect(result.current.sortedScores).toHaveLength(0)
  })

  it('handles custom proficiency levels with non-equal spacing', () => {
    const customScores: LMGBScoreReporting[] = [
      {
        score: 7.5,
        title: 'Assignment 1',
        type: 'assignment',
        submitted_at: '2025-01-01T10:00:00Z',
        links: {outcome: '1'},
      },
      {
        score: 5.2,
        title: 'Quiz 1',
        type: 'quiz',
        submitted_at: '2025-01-02T10:00:00Z',
        links: {outcome: '1'},
      },
    ]

    const {result} = renderHook(() => useOutcomesChart(customScores))

    // Should handle scores between non-equal intervals
    expect(result.current.sortedScores).toHaveLength(2)
    expect(result.current.sortedScores[0].score).toBe(7.5)
    expect(result.current.sortedScores[1].score).toBe(5.2)
  })

  describe('mastery scale configurations', () => {
    it('handles 1 level scale with icons', () => {
      const oneLevel = [{points: 3, color: '#00ff00', description: 'Mastery', mastery: true}]

      const {result} = renderHook(() => useOutcomesChart(mockScores, oneLevel))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 2 level scale with mastery at top', () => {
      const twoLevels = [
        {points: 4, color: '#00ff00', description: 'Mastery', mastery: true},
        {points: 2, color: '#ffff00', description: 'Near Mastery'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, twoLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 2 level scale with mastery at bottom', () => {
      const twoLevels = [
        {points: 4, color: '#0000ff', description: 'Exceeds'},
        {points: 2, color: '#00ff00', description: 'Mastery', mastery: true},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, twoLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 3 level scale with mastery at top', () => {
      const threeLevels = [
        {points: 5, color: '#00ff00', description: 'Mastery', mastery: true},
        {points: 3, color: '#ffff00', description: 'Near Mastery'},
        {points: 1, color: '#ff0000', description: 'Remediation'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, threeLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 3 level scale with mastery at middle', () => {
      const threeLevels = [
        {points: 5, color: '#0000ff', description: 'Exceeds'},
        {points: 3, color: '#00ff00', description: 'Mastery', mastery: true},
        {points: 1, color: '#ffff00', description: 'Near Mastery'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, threeLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 3 level scale with mastery at bottom (uses numbers)', () => {
      const threeLevels = [
        {points: 5, color: '#0000ff', description: 'Exceeds'},
        {points: 3, color: '#ffff00', description: 'Near Mastery'},
        {points: 1, color: '#00ff00', description: 'Mastery', mastery: true},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, threeLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 4 level scale with standard mastery position', () => {
      const fourLevels = [
        {points: 10, color: '#0000ff', description: 'Exceeds'},
        {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
        {points: 5, color: '#ffff00', description: 'Near Mastery'},
        {points: 2, color: '#ff0000', description: 'Remediation'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, fourLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 4 level scale with non-standard mastery position (uses numbers)', () => {
      const fourLevels = [
        {points: 10, color: '#0000ff', description: 'Level 4', mastery: true},
        {points: 7, color: '#00ff00', description: 'Level 3'},
        {points: 5, color: '#ffff00', description: 'Level 2'},
        {points: 2, color: '#ff0000', description: 'Level 1'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, fourLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 5 level scale with standard mastery position', () => {
      const fiveLevels = [
        {points: 10, color: '#0000ff', description: 'Distinguished'},
        {points: 8, color: '#00ff00', description: 'Proficient', mastery: true},
        {points: 6, color: '#ffff00', description: 'Nearly Proficient'},
        {points: 4, color: '#ffa500', description: 'Developing'},
        {points: 2, color: '#ff0000', description: 'Beginning'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, fiveLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 5 level scale with non-standard mastery position (uses numbers)', () => {
      const fiveLevels = [
        {points: 10, color: '#0000ff', description: 'Level 5', mastery: true},
        {points: 8, color: '#00ff00', description: 'Level 4'},
        {points: 6, color: '#ffff00', description: 'Level 3'},
        {points: 4, color: '#ffa500', description: 'Level 2'},
        {points: 2, color: '#ff0000', description: 'Level 1'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, fiveLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles 6+ level scales (always uses numbers)', () => {
      const sixLevels = [
        {points: 12, color: '#0000ff', description: 'Level 6'},
        {points: 10, color: '#00aaff', description: 'Level 5'},
        {points: 8, color: '#00ff00', description: 'Level 4', mastery: true},
        {points: 6, color: '#ffff00', description: 'Level 3'},
        {points: 4, color: '#ffa500', description: 'Level 2'},
        {points: 2, color: '#ff0000', description: 'Level 1'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, sixLevels))

      expect(result.current.sortedScores).toHaveLength(3)
    })

    it('handles scale with no mastery set (uses numbers)', () => {
      const noMastery = [
        {points: 4, color: '#0000ff', description: 'Level 4'},
        {points: 3, color: '#00ff00', description: 'Level 3'},
        {points: 2, color: '#ffff00', description: 'Level 2'},
        {points: 1, color: '#ff0000', description: 'Level 1'},
      ]

      const {result} = renderHook(() => useOutcomesChart(mockScores, noMastery))

      expect(result.current.sortedScores).toHaveLength(3)
    })
  })
})
