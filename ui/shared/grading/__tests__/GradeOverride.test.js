/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import GradeOverride from '../GradeOverride'

describe('GradeOverride', () => {
  describe('#percentage', () => {
    it('is the given percentage', () => {
      expect(new GradeOverride({percentage: 91.23}).percentage).toEqual(91.23)
    })

    it('defaults to null', () => {
      expect(new GradeOverride({}).percentage).toEqual(null)
    })
  })

  describe('#schemeKey', () => {
    it('is the given schemeKey', () => {
      expect(new GradeOverride({schemeKey: 'A'}).schemeKey).toEqual('A')
    })

    it('defaults to null', () => {
      expect(new GradeOverride({}).percentage).toEqual(null)
    })
  })

  describe('#equals()', () => {
    it('returns true when two GradeOverrides have the same values', () => {
      const gradeA = new GradeOverride({percentage: 100.0, schemeKey: 'A'})
      const gradeB = new GradeOverride({percentage: 100.0, schemeKey: 'A'})
      expect(gradeA.equals(gradeB)).toBe(true)
    })

    it('returns false when two GradeOverrides have different percentages', () => {
      const gradeA = new GradeOverride({percentage: 100.0, schemeKey: 'A'})
      const gradeB = new GradeOverride({percentage: 99.9, schemeKey: 'A'})
      expect(gradeA.equals(gradeB)).toBe(false)
    })

    it('returns false when two GradeOverrides have different schemeKeys', () => {
      const gradeA = new GradeOverride({percentage: 100.0, schemeKey: 'A'})
      const gradeB = new GradeOverride({percentage: 100.0, schemeKey: 'B'})
      expect(gradeA.equals(gradeB)).toBe(false)
    })
  })
})
