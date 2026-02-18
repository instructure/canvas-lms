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

import {describe, it, expect} from 'vitest'
import {
  determineMasteryLevel,
  getColorForLevel,
  getDescriptionForLevel,
  type ProficiencyRating,
} from '../masteryScaleLogic'

describe('masteryScaleLogic', () => {
  describe('determineMasteryLevel', () => {
    describe('unassessed cases', () => {
      it('returns unassessed for null points', () => {
        const ratings: ProficiencyRating[] = [
          {points: 4, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 3, color: '#ffff00', description: 'Near Mastery'},
        ]
        expect(determineMasteryLevel(null, ratings)).toBe('unassessed')
      })

      it('returns unassessed for undefined points', () => {
        const ratings: ProficiencyRating[] = [
          {points: 4, color: '#00ff00', description: 'Mastery', mastery: true},
        ]
        expect(determineMasteryLevel(undefined, ratings)).toBe('unassessed')
      })

      it('returns unassessed for empty ratings array', () => {
        expect(determineMasteryLevel(5, [])).toBe('unassessed')
      })
    })

    describe('1 level scale', () => {
      it('returns mastery for score at or above the level', () => {
        const ratings: ProficiencyRating[] = [
          {points: 3, color: '#00ff00', description: 'Mastery', mastery: true},
        ]
        expect(determineMasteryLevel(3, ratings)).toBe('mastery')
        expect(determineMasteryLevel(5, ratings)).toBe('mastery')
      })

      it('returns mastery even for score below the threshold (1-level scale has no lower level)', () => {
        const ratings: ProficiencyRating[] = [
          {points: 3, color: '#00ff00', description: 'Mastery', mastery: true},
        ]
        // In a 1-level scale, scores below threshold still map to that single level
        expect(determineMasteryLevel(2, ratings)).toBe('mastery')
      })
    })

    describe('2 level scale', () => {
      it('returns correct icons when mastery is at highest level', () => {
        const ratings: ProficiencyRating[] = [
          {points: 4, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 2, color: '#ffff00', description: 'Not Mastered'},
        ]
        expect(determineMasteryLevel(4, ratings)).toBe('mastery')
        expect(determineMasteryLevel(5, ratings)).toBe('mastery')
        expect(determineMasteryLevel(2, ratings)).toBe('near_mastery')
        expect(determineMasteryLevel(3, ratings)).toBe('near_mastery')
      })

      it('returns correct icons when mastery is at lowest level', () => {
        const ratings: ProficiencyRating[] = [
          {points: 4, color: '#0000ff', description: 'Exceeds'},
          {points: 2, color: '#00ff00', description: 'Mastery', mastery: true},
        ]
        expect(determineMasteryLevel(5, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(4, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(2, ratings)).toBe('mastery')
        expect(determineMasteryLevel(3, ratings)).toBe('mastery')
      })
    })

    describe('3 level scale', () => {
      it('returns correct icons when mastery is at level 3 (highest)', () => {
        const ratings: ProficiencyRating[] = [
          {points: 6, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 4, color: '#ffff00', description: 'Near Mastery'},
          {points: 2, color: '#ff0000', description: 'Below Mastery'},
        ]
        expect(determineMasteryLevel(6, ratings)).toBe('mastery')
        expect(determineMasteryLevel(4, ratings)).toBe('near_mastery')
        expect(determineMasteryLevel(2, ratings)).toBe('remediation')
      })

      it('returns correct icons when mastery is at level 2 (middle)', () => {
        const ratings: ProficiencyRating[] = [
          {points: 6, color: '#0000ff', description: 'Exceeds Mastery'},
          {points: 4, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 2, color: '#ffff00', description: 'Near Mastery'},
        ]
        expect(determineMasteryLevel(6, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(4, ratings)).toBe('mastery')
        expect(determineMasteryLevel(2, ratings)).toBe('near_mastery')
      })

      it('returns numbers when mastery is at level 1 (lowest)', () => {
        const ratings: ProficiencyRating[] = [
          {points: 6, color: '#0000ff', description: 'Level 3'},
          {points: 4, color: '#00ff00', description: 'Level 2'},
          {points: 2, color: '#ff0000', description: 'Level 1', mastery: true},
        ]
        expect(determineMasteryLevel(6, ratings)).toBe(1)
        expect(determineMasteryLevel(4, ratings)).toBe(2)
        expect(determineMasteryLevel(2, ratings)).toBe(3)
      })
    })

    describe('4 level scale', () => {
      it('returns correct icons when mastery is at level 3', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#0000ff', description: 'Exceeds Mastery'},
          {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 5, color: '#ffff00', description: 'Near Mastery'},
          {points: 3, color: '#ff0000', description: 'Below Mastery'},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(7, ratings)).toBe('mastery')
        expect(determineMasteryLevel(5, ratings)).toBe('near_mastery')
        expect(determineMasteryLevel(3, ratings)).toBe('remediation')
      })

      it('returns numbers when mastery is at level 4 (highest)', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#00ff00', description: 'Level 4', mastery: true},
          {points: 7, color: '#ffff00', description: 'Level 3'},
          {points: 5, color: '#ffa500', description: 'Level 2'},
          {points: 3, color: '#ff0000', description: 'Level 1'},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe(1)
        expect(determineMasteryLevel(7, ratings)).toBe(2)
      })

      it('returns numbers when mastery is at level 2', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#0000ff', description: 'Level 4'},
          {points: 7, color: '#00ff00', description: 'Level 3'},
          {points: 5, color: '#ffff00', description: 'Level 2', mastery: true},
          {points: 3, color: '#ff0000', description: 'Level 1'},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe(1)
        expect(determineMasteryLevel(5, ratings)).toBe(3)
      })

      it('returns numbers when mastery is at level 1 (lowest)', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#0000ff', description: 'Level 4'},
          {points: 7, color: '#00ff00', description: 'Level 3'},
          {points: 5, color: '#ffff00', description: 'Level 2'},
          {points: 3, color: '#ff0000', description: 'Level 1', mastery: true},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe(1)
        expect(determineMasteryLevel(3, ratings)).toBe(4)
      })
    })

    describe('5 level scale', () => {
      it('returns correct icons when mastery is at level 4', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#0000ff', description: 'Distinguished'},
          {points: 7, color: '#00ff00', description: 'Proficient', mastery: true},
          {points: 5, color: '#ffff00', description: 'Nearly Proficient'},
          {points: 3, color: '#ffa500', description: 'Developing'},
          {points: 0, color: '#ff0000', description: 'Beginning'},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(7, ratings)).toBe('mastery')
        expect(determineMasteryLevel(5, ratings)).toBe('near_mastery')
        expect(determineMasteryLevel(3, ratings)).toBe('remediation')
        expect(determineMasteryLevel(0, ratings)).toBe('no_evidence')
      })

      it('returns numbers when mastery is at level 5 (highest)', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#00ff00', description: 'Level 5', mastery: true},
          {points: 7, color: '#ffff00', description: 'Level 4'},
          {points: 5, color: '#ffa500', description: 'Level 3'},
          {points: 3, color: '#ff8800', description: 'Level 2'},
          {points: 0, color: '#ff0000', description: 'Level 1'},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe(1)
        expect(determineMasteryLevel(7, ratings)).toBe(2)
        expect(determineMasteryLevel(0, ratings)).toBe(5)
      })

      it('returns numbers when mastery is at level 3', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#0000ff', description: 'Level 5'},
          {points: 7, color: '#00ff00', description: 'Level 4'},
          {points: 5, color: '#ffff00', description: 'Level 3', mastery: true},
          {points: 3, color: '#ffa500', description: 'Level 2'},
          {points: 0, color: '#ff0000', description: 'Level 1'},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe(1)
        expect(determineMasteryLevel(5, ratings)).toBe(3)
      })
    })

    describe('6+ level scale', () => {
      it('always returns numbers for 6 levels', () => {
        const ratings: ProficiencyRating[] = [
          {points: 10, color: '#0000ff', description: 'Level 6'},
          {points: 8, color: '#0066ff', description: 'Level 5'},
          {points: 6, color: '#00ff00', description: 'Level 4', mastery: true},
          {points: 4, color: '#ffff00', description: 'Level 3'},
          {points: 2, color: '#ffa500', description: 'Level 2'},
          {points: 0, color: '#ff0000', description: 'Level 1'},
        ]
        expect(determineMasteryLevel(10, ratings)).toBe(1)
        expect(determineMasteryLevel(8, ratings)).toBe(2)
        expect(determineMasteryLevel(6, ratings)).toBe(3)
        expect(determineMasteryLevel(4, ratings)).toBe(4)
        expect(determineMasteryLevel(2, ratings)).toBe(5)
        expect(determineMasteryLevel(0, ratings)).toBe(6)
      })

      it('always returns numbers for 7+ levels', () => {
        const ratings: ProficiencyRating[] = [
          {points: 12, color: '#0000ff', description: 'Level 7'},
          {points: 10, color: '#0066ff', description: 'Level 6'},
          {points: 8, color: '#00ccff', description: 'Level 5'},
          {points: 6, color: '#00ff00', description: 'Level 4', mastery: true},
          {points: 4, color: '#ffff00', description: 'Level 3'},
          {points: 2, color: '#ffa500', description: 'Level 2'},
          {points: 0, color: '#ff0000', description: 'Level 1'},
        ]
        expect(determineMasteryLevel(12, ratings)).toBe(1)
        expect(determineMasteryLevel(10, ratings)).toBe(2)
        expect(determineMasteryLevel(0, ratings)).toBe(7)
      })
    })

    describe('non-equal spacing', () => {
      it('handles non-uniform point gaps correctly', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#0000ff', description: 'Exceeds'},
          {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 5, color: '#ffff00', description: 'Near Mastery'},
          {points: 3, color: '#ff0000', description: 'Below'},
        ]
        // Scores are assigned to the level they've achieved (>=)
        expect(determineMasteryLevel(9, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(8, ratings)).toBe('mastery') // >= 7 but < 9
        expect(determineMasteryLevel(7, ratings)).toBe('mastery')
        expect(determineMasteryLevel(6, ratings)).toBe('near_mastery') // >= 5 but < 7
        expect(determineMasteryLevel(5, ratings)).toBe('near_mastery')
        expect(determineMasteryLevel(4, ratings)).toBe('remediation') // >= 3 but < 5
        expect(determineMasteryLevel(3, ratings)).toBe('remediation')
        expect(determineMasteryLevel(2, ratings)).toBe('remediation') // < 3, belongs to lowest level
      })

      it('handles 0, 3, 5, 7, 9 point scale', () => {
        const ratings: ProficiencyRating[] = [
          {points: 9, color: '#0000ff', description: 'Distinguished'},
          {points: 7, color: '#00ff00', description: 'Proficient', mastery: true},
          {points: 5, color: '#ffff00', description: 'Nearly Proficient'},
          {points: 3, color: '#ffa500', description: 'Developing'},
          {points: 0, color: '#ff0000', description: 'Beginning'},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(7, ratings)).toBe('mastery')
        expect(determineMasteryLevel(5, ratings)).toBe('near_mastery')
        expect(determineMasteryLevel(3, ratings)).toBe('remediation')
        expect(determineMasteryLevel(0, ratings)).toBe('no_evidence')
      })
    })

    describe('unsorted ratings', () => {
      it('handles ratings that are not pre-sorted', () => {
        const ratings: ProficiencyRating[] = [
          {points: 3, color: '#ff0000', description: 'Below'},
          {points: 9, color: '#0000ff', description: 'Exceeds'},
          {points: 5, color: '#ffff00', description: 'Near Mastery'},
          {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
        ]
        expect(determineMasteryLevel(9, ratings)).toBe('exceeds_mastery')
        expect(determineMasteryLevel(7, ratings)).toBe('mastery')
        expect(determineMasteryLevel(5, ratings)).toBe('near_mastery')
        expect(determineMasteryLevel(3, ratings)).toBe('remediation')
      })
    })

    describe('edge cases', () => {
      it('handles score exactly at rating threshold', () => {
        const ratings: ProficiencyRating[] = [
          {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 5, color: '#ffff00', description: 'Near Mastery'},
        ]
        expect(determineMasteryLevel(7, ratings)).toBe('mastery')
        expect(determineMasteryLevel(5, ratings)).toBe('near_mastery')
      })

      it('handles score between rating thresholds', () => {
        const ratings: ProficiencyRating[] = [
          {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 5, color: '#ffff00', description: 'Near Mastery'},
        ]
        // Score 6 is >= 5 but < 7, so it belongs to the 5-point level
        expect(determineMasteryLevel(6, ratings)).toBe('near_mastery')
        // Score 4 is < 5, so it belongs to the lowest level (still near_mastery)
        expect(determineMasteryLevel(4, ratings)).toBe('near_mastery')
      })

      it('handles score above highest rating', () => {
        const ratings: ProficiencyRating[] = [
          {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 5, color: '#ffff00', description: 'Near Mastery'},
        ]
        expect(determineMasteryLevel(10, ratings)).toBe('mastery')
      })

      it('handles score below lowest rating - belongs to lowest level', () => {
        const ratings: ProficiencyRating[] = [
          {points: 7, color: '#00ff00', description: 'Mastery', mastery: true},
          {points: 5, color: '#ffff00', description: 'Near Mastery'},
        ]
        // Score below all thresholds still belongs to the lowest level
        expect(determineMasteryLevel(2, ratings)).toBe('near_mastery')
      })
    })
  })

  describe('getColorForLevel', () => {
    const ratings: ProficiencyRating[] = [
      {points: 9, color: '#0000ff', description: 'Level 4'},
      {points: 7, color: '#00ff00', description: 'Level 3'},
      {points: 5, color: '#ffff00', description: 'Level 2'},
      {points: 3, color: '#ff0000', description: 'Level 1'},
    ]

    it('returns correct color for each level', () => {
      expect(getColorForLevel(1, ratings)).toBe('#0000ff')
      expect(getColorForLevel(2, ratings)).toBe('#00ff00')
      expect(getColorForLevel(3, ratings)).toBe('#ffff00')
      expect(getColorForLevel(4, ratings)).toBe('#ff0000')
    })

    it('returns undefined for invalid level', () => {
      expect(getColorForLevel(0, ratings)).toBeUndefined()
      expect(getColorForLevel(5, ratings)).toBeUndefined()
    })
  })

  describe('getDescriptionForLevel', () => {
    const ratings: ProficiencyRating[] = [
      {points: 9, color: '#0000ff', description: 'Excellent'},
      {points: 7, color: '#00ff00', description: 'Good'},
      {points: 5, color: '#ffff00', description: 'Fair'},
      {points: 3, color: '#ff0000', description: 'Poor'},
    ]

    it('returns correct description for each level', () => {
      expect(getDescriptionForLevel(1, ratings)).toBe('Excellent')
      expect(getDescriptionForLevel(2, ratings)).toBe('Good')
      expect(getDescriptionForLevel(3, ratings)).toBe('Fair')
      expect(getDescriptionForLevel(4, ratings)).toBe('Poor')
    })

    it('returns undefined for invalid level', () => {
      expect(getDescriptionForLevel(0, ratings)).toBeUndefined()
      expect(getDescriptionForLevel(5, ratings)).toBeUndefined()
    })
  })
})
