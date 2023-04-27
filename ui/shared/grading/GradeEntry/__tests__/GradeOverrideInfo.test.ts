// @ts-nocheck
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

import GradeOverride from '../../GradeOverride'
import GradeOverrideInfo from '../GradeOverrideInfo'
import {EnterGradesAs} from '../index'

describe('GradeOverrideInfo', () => {
  let attr

  beforeEach(() => {
    attr = {
      enteredAs: EnterGradesAs.PERCENTAGE,
      grade: new GradeOverride({
        percentage: 91.1,
        schemeKey: 'A',
      }),
      valid: true,
    }
  })

  describe('#enteredAs', () => {
    it('is the given enteredAs', () => {
      expect(new GradeOverrideInfo(attr).enteredAs).toEqual(EnterGradesAs.PERCENTAGE)
    })

    it('defaults to null', () => {
      expect(new GradeOverrideInfo({}).enteredAs).toEqual(null)
    })
  })

  describe('#grade', () => {
    it('is the given grade', () => {
      expect(new GradeOverrideInfo(attr).grade).toEqual(attr.grade)
    })

    it('defaults to null', () => {
      expect(new GradeOverrideInfo({}).grade).toEqual(null)
    })
  })

  describe('#valid', () => {
    it('is the given value of .valid', () => {
      expect(new GradeOverrideInfo(attr).valid).toEqual(true)
    })

    it('defaults to null', () => {
      expect(new GradeOverrideInfo({}).valid).toEqual(null)
    })
  })

  describe('#equals()', () => {
    function createWithGrade(gradeAttr) {
      return new GradeOverrideInfo({...attr, grade: new GradeOverride(gradeAttr)})
    }

    it('returns true when two instances have grades with the same values', () => {
      const gradeInfoA = createWithGrade({percentage: 100.0, schemeKey: 'A'})
      const gradeInfoB = createWithGrade({percentage: 100.0, schemeKey: 'A'})
      expect(gradeInfoA.equals(gradeInfoB)).toBe(true)
    })

    it('returns false when two instances have grades with different percentages', () => {
      const gradeInfoA = createWithGrade({percentage: 100.0, schemeKey: 'A'})
      const gradeInfoB = createWithGrade({percentage: 99.9, schemeKey: 'A'})
      expect(gradeInfoA.equals(gradeInfoB)).toBe(false)
    })

    it('returns false when two instances have grades with different schemeKeys', () => {
      const gradeInfoA = createWithGrade({percentage: 100.0, schemeKey: 'A'})
      const gradeInfoB = createWithGrade({percentage: 100.0, schemeKey: 'B'})
      expect(gradeInfoA.equals(gradeInfoB)).toBe(false)
    })
  })
})
