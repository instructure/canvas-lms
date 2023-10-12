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

import GradeOverrideEntry from '../GradeOverrideEntry'
import {EnterGradesAs} from '../index'

describe('GradeOverrideEntry', () => {
  let options

  beforeEach(() => {
    options = {
      gradingScheme: {
        data: [
          ['A', 0.9],
          ['B', 0.8],
          ['C', 0.7],
          ['D', 0.6],
          ['F', 0.5],
        ],
        id: '2801',
        title: 'Default Grading Scheme',
      },
    }
  })

  describe('#enterGradesAs', () => {
    // TODO: GRADE-1926 Return `EnterGradesAs.GRADING_SCHEME` when a grading scheme is used
    /* jest/no-disabled-tests */
    it.skip(`is '${EnterGradesAs.GRADING_SCHEME}' when using grading scheme`, () => {
      const gradeEntry = new GradeOverrideEntry(options)
      expect(gradeEntry.enterGradesAs).toEqual(EnterGradesAs.GRADING_SCHEME)
    })

    it(`is '${EnterGradesAs.PERCENTAGE}' when not using grading scheme`, () => {
      options.gradingScheme = null
      const gradeEntry = new GradeOverrideEntry(options)
      expect(gradeEntry.enterGradesAs).toEqual(EnterGradesAs.PERCENTAGE)
    })
  })

  describe('#gradingScheme', () => {
    it('is the given grading scheme when using grading scheme', () => {
      const gradeEntry = new GradeOverrideEntry(options)
      expect(gradeEntry.gradingScheme).toEqual(options.gradingScheme)
    })

    it('is null when not using grading scheme', () => {
      options.gradingScheme = null
      const gradeEntry = new GradeOverrideEntry(options)
      expect(gradeEntry.gradingScheme).toBe(null)
    })
  })

  describe('#hasGradeChanged()', () => {
    let currentValue // The grade currently represented by the grade input.
    let assignedValue // The persisted grade given to the student.
    let previousValue // A pending grade, either invalid or currently saving.

    beforeEach(() => {
      currentValue = null
      assignedValue = null
      previousValue = null
    })

    function hasGradeChanged() {
      const gradeEntry = new GradeOverrideEntry(options)

      const assignedGradeInfo = gradeEntry.parseValue(assignedValue)
      const currentGradeInfo = gradeEntry.parseValue(currentValue)
      const previousGradeInfo = previousValue == null ? null : gradeEntry.parseValue(previousValue)

      return gradeEntry.hasGradeChanged(assignedGradeInfo, currentGradeInfo, previousGradeInfo)
    }

    describe('when no grade is assigned and no grade was previously entered', () => {
      it('returns false when no value has been entered', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns false when only whitespace has been entered', () => {
        currentValue = '     '
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns true when any other value has been entered', () => {
        currentValue = 'invalid'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when using points based grading scheme and user enters a pct (invalid) then a letter (valid, same value as pct)', () => {
        const gradeEntryOptions = {
          gradingScheme: {
            data: [
              ['A', 0.9],
              ['B', 0.8],
              ['C', 0.7],
              ['D', 0.6],
              ['F', 0.5],
            ],
            id: 'some-id',
            pointsBased: true,
            scalingFactor: 4.0,
            title: 'A Points Based Grading Scheme',
          },
        }

        const gradeOverrideEntry = new GradeOverrideEntry(gradeEntryOptions)
        const assignedGradeInfo = gradeOverrideEntry.parseValue('70', true)
        const currentGradeInfo = gradeOverrideEntry.parseValue('C', true)
        expect(gradeOverrideEntry.hasGradeChanged(assignedGradeInfo, currentGradeInfo)).toBe(true)
      })
    })

    describe('when no grade is assigned and a valid grade was previously entered', () => {
      beforeEach(() => {
        previousValue = '91.1%'
        currentValue = '91.1%'
      })

      it('returns false when the same grade is entered', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns true when a different valid grade is entered', () => {
        currentValue = '89.9%'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when an invalid grade is entered', () => {
        currentValue = 'invalid'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when the grade is cleared', () => {
        currentValue = ''
        expect(hasGradeChanged()).toBe(true)
      })
    })

    describe('when no grade is assigned and an invalid grade was previously entered', () => {
      beforeEach(() => {
        previousValue = 'invalid'
        currentValue = 'invalid'
      })

      it('returns false when the same invalid grade is entered', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns true when a different invalid grade is entered', () => {
        currentValue = 'also invalid'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when a valid grade is entered', () => {
        currentValue = '91.1%'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when the invalid grade is cleared', () => {
        currentValue = ''
        expect(hasGradeChanged()).toBe(true)
      })
    })

    describe('when a grade is assigned and no different grade was previously entered', () => {
      beforeEach(() => {
        assignedValue = '89.9%'
        currentValue = '89.9%'
      })

      it('returns false when the same percentage grade is entered', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns false when the same percentage grade is entered with extra zeros', () => {
        currentValue = '89.9000%'
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns false when the same scheme key is entered using the grading scheme', () => {
        assignedValue = '80%' // Becomes an "B" in the grading scheme
        currentValue = 'B'
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns false when the same scheme key is entered but the percentage was different', () => {
        assignedValue = '95.0%' // Becomes an "A" in the grading scheme
        /*
         * A value of "A" is not considered different, even though the
         * percentage would ordinarily be interpreted as 90%, because the user
         * might not have actually changed the value of the input.
         */
        currentValue = 'A'
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns true when a different valid percentage is entered', () => {
        currentValue = '91.1%'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when an invalid grade is entered', () => {
        currentValue = 'invalid'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when the grade is cleared', () => {
        currentValue = ''
        expect(hasGradeChanged()).toBe(true)
      })
    })

    describe('when a grade is assigned and a different valid grade was previously entered', () => {
      beforeEach(() => {
        assignedValue = '89.9%'
        previousValue = '90.0%'
        currentValue = '90.0%'
      })

      it('returns false when the previously entered percentage grade is entered', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns false when the previously entered percentage grade is entered with extra zeros', () => {
        currentValue = '90.0000%'
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns false when the previously entered scheme key is entered using the grading scheme', () => {
        currentValue = 'A'
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns false when the previously entered scheme key is entered but the percentage was different', () => {
        previousValue = '95.0%' // Becomes an "A" in the grading scheme
        /*
         * A value of "A" is not considered different, even though the
         * percentage would ordinarily be interpreted as 90%, because the user
         * might not have actually changed the value of the input.
         */
        currentValue = 'A'
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns true when a different valid percentage is entered', () => {
        currentValue = '91.1%'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when an invalid grade is entered', () => {
        currentValue = 'invalid'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when the grade is cleared', () => {
        currentValue = ''
        expect(hasGradeChanged()).toBe(true)
      })
    })

    describe('when a grade is assigned and an invalid grade was previously entered', () => {
      beforeEach(() => {
        assignedValue = '89.9%'
        previousValue = 'invalid'
        currentValue = 'invalid'
      })

      it('returns false when the same invalid grade is entered', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      it('returns true when a different invalid grade is entered', () => {
        currentValue = 'also invalid'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when a valid grade is entered', () => {
        currentValue = '91.1%'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when the assigned grade is entered as a percentage', () => {
        currentValue = '89.9%'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when the assigned grade is entered using the scheme key', () => {
        currentValue = 'B'
        expect(hasGradeChanged()).toBe(true)
      })

      it('returns true when the invalid grade is cleared', () => {
        currentValue = ''
        expect(hasGradeChanged()).toBe(true)
      })
    })
  })

  describe('#parseValue()', () => {
    function parseValue(value) {
      return new GradeOverrideEntry(options).parseValue(value)
    }

    describe('.grade', () => {
      it('is set to null when given non-numerical string not in the grading scheme', () => {
        expect(parseValue('B-').grade).toEqual(null)
      })

      it('is set to null when the value is blank', () => {
        expect(parseValue('  ').grade).toEqual(null)
      })

      it('is set to null when the value is "EX"', () => {
        expect(parseValue('EX').grade).toEqual(null)
      })

      describe('.percentage', () => {
        it('is set to the lower bound for a matching scheme key', () => {
          expect(parseValue('B').grade?.percentage).toEqual(80.0)
        })

        it('is set to the decimal form of an explicit percentage', () => {
          expect(parseValue('83.45%').grade?.percentage).toEqual(83.45)
        })

        it('is set to the decimal of a given integer', () => {
          expect(parseValue(83).grade?.percentage).toEqual(83.0)
        })

        it('is set to the decimal of a given stringified integer', () => {
          expect(parseValue('73').grade?.percentage).toEqual(73.0)
        })

        it('is set to the given decimal', () => {
          expect(parseValue(73.45).grade?.percentage).toEqual(73.45)
        })

        it('is set to the decimal of a given stringified decimal', () => {
          expect(parseValue('73.45').grade?.percentage).toEqual(73.45)
        })

        it('converts percentages using the "％" symbol', () => {
          expect(parseValue('83.35％').grade?.percentage).toEqual(83.35)
        })

        it('converts percentages using the "﹪" symbol', () => {
          expect(parseValue('83.35﹪').grade?.percentage).toEqual(83.35)
        })

        it('converts percentages using the "٪" symbol', () => {
          expect(parseValue('83.35٪').grade?.percentage).toEqual(83.35)
        })

        it('is rounded to 15 decimal places', () => {
          const percentage = parseValue(81.1234567890123456789).grade?.percentage
          expect(String(percentage)).toEqual('81.12345678901235')
        })

        it('is set to the lower bound for a matching numerical scheme key', () => {
          options.gradingScheme.data = [
            ['4.0', 0.9],
            ['3.0', 0.8],
            ['2.0', 0.7],
            ['1.0', 0.6],
            ['0.0', 0.5],
          ]
          expect(parseValue('3.0').grade?.percentage).toEqual(80.0)
        })

        it('is set to the lower bound for a matching percentage scheme key', () => {
          options.gradingScheme.data = [
            ['95%', 0.9],
            ['85%', 0.8],
            ['75%', 0.7],
            ['65%', 0.6],
            ['0%', 0.5],
          ]
          expect(parseValue('85%').grade?.percentage).toEqual(80.0)
        })

        it('is set to zero when given zero', () => {
          expect(parseValue(0).grade?.percentage).toEqual(0)
        })

        it('is set to the given numerical value when not using a grading scheme', () => {
          options.gradingScheme = null
          expect(parseValue('81.45').grade?.percentage).toEqual(81.45)
        })
      })

      describe('.schemeKey', () => {
        it('is set to the matching scheme key when given an integer', () => {
          expect(parseValue(81).grade?.schemeKey).toEqual('B')
        })

        it('is set to the matching scheme key with the same case', () => {
          expect(parseValue('B').grade?.schemeKey).toEqual('B')
        })

        it('uses the exact scheme key when matching with different case', () => {
          expect(parseValue('b').grade?.schemeKey).toEqual('B')
        })

        it('matches an explicit percentage value to a scheme value for the grade scheme key', () => {
          expect(parseValue('83.45%').grade?.schemeKey).toEqual('B')
        })

        it('uses numerical values as implicit percentage values', () => {
          expect(parseValue(83).grade?.schemeKey).toEqual('B')
        })

        it('is set to the matching scheme key when given a stringified integer', () => {
          expect(parseValue('73').grade?.schemeKey).toEqual('C')
        })

        it('is set to the matching scheme key when given an decimal', () => {
          expect(parseValue(73.45).grade?.schemeKey).toEqual('C')
        })

        it('is set to the matching scheme key when given a stringified decimal', () => {
          expect(parseValue('73.45').grade?.schemeKey).toEqual('C')
        })

        it('converts percentages using the "％" symbol', () => {
          expect(parseValue('83.35％').grade?.schemeKey).toEqual('B')
        })

        it('converts percentages using the "﹪" symbol', () => {
          expect(parseValue('83.35﹪').grade?.schemeKey).toEqual('B')
        })

        it('converts percentages using the "٪" symbol', () => {
          expect(parseValue('83.35٪').grade?.schemeKey).toEqual('B')
        })

        it('is set to the matching scheme key when given a numerical scheme key', () => {
          options.gradingScheme.data = [
            ['4.0', 0.9],
            ['3.0', 0.8],
            ['2.0', 0.7],
            ['1.0', 0.6],
            ['0.0', 0.5],
          ]
          expect(parseValue('3.0').grade?.schemeKey).toEqual('3.0')
        })

        it('is set to the matching scheme key when given a percentage scheme key', () => {
          options.gradingScheme.data = [
            ['95%', 0.9],
            ['85%', 0.8],
            ['75%', 0.7],
            ['65%', 0.6],
            ['0%', 0.5],
          ]
          expect(parseValue('95%').grade?.schemeKey).toEqual('95%')
        })

        it('is set to the lowest scheme key when given zero', () => {
          expect(parseValue(0).grade?.schemeKey).toEqual('F')
        })

        it('ignores whitespace from the given value when setting the grade', () => {
          expect(parseValue(' B ').grade?.schemeKey).toEqual('B')
        })

        it('is set to null when not using a grading scheme', () => {
          options.gradingScheme = null
          expect(parseValue('81.45').grade?.schemeKey).toEqual(null)
        })
      })

      describe('when not using a grading scheme', () => {
        it('is set to null when given a non-numerical value', () => {
          options.gradingScheme = null
          expect(parseValue('B').grade).toEqual(null)
        })
      })
    })

    describe('.enteredAs', () => {
      const {GRADING_SCHEME, PERCENTAGE} = EnterGradesAs

      it(`is set to "${PERCENTAGE}" when given a number`, () => {
        expect(parseValue('8.34').enteredAs).toEqual(PERCENTAGE)
      })

      it(`is set to "${PERCENTAGE}" when given a percentage`, () => {
        expect(parseValue('83.45%').enteredAs).toEqual(PERCENTAGE)
      })

      it(`is set to "${GRADING_SCHEME}" when given a grading scheme key`, () => {
        expect(parseValue('B').enteredAs).toEqual(GRADING_SCHEME)
      })

      it(`is set to "${GRADING_SCHEME}" when given a numerical value which matches a grading scheme key`, () => {
        options.gradingScheme.data = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseValue('3.0').enteredAs).toEqual(GRADING_SCHEME)
      })

      it(`is set to "${GRADING_SCHEME}" when given a percentage value which matches a grading scheme key`, () => {
        options.gradingScheme.data = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseValue('85%').enteredAs).toEqual(GRADING_SCHEME)
      })

      it('is set to null when given a non-numerical string not in the grading scheme', () => {
        expect(parseValue('B-').enteredAs).toEqual(null)
      })

      it('is set to null when given "EX"', () => {
        expect(parseValue('EX').enteredAs).toEqual(null)
      })

      it('is set to null when the grade is cleared', () => {
        expect(parseValue('').enteredAs).toEqual(null)
      })

      describe('when not using a grading scheme', () => {
        beforeEach(() => {
          options.gradingScheme = null
        })

        it(`is set to "${PERCENTAGE}" when given a number`, () => {
          expect(parseValue('81.45%').enteredAs).toEqual(PERCENTAGE)
        })

        it(`is set to "${PERCENTAGE}" when given a percentage`, () => {
          expect(parseValue('81.45').enteredAs).toEqual(PERCENTAGE)
        })

        it('is set to false when given a non-numerical value', () => {
          expect(parseValue('B').valid).toBe(false)
        })
      })
    })

    describe('.valid', () => {
      it('is set to true when the grade is a valid number', () => {
        expect(parseValue('8.34').valid).toBe(true)
      })

      it('is set to true when the grade is a valid percentage', () => {
        expect(parseValue('83.4%').valid).toBe(true)
      })

      it('is set to true when the grade is a valid grading scheme key', () => {
        expect(parseValue('B').valid).toBe(true)
      })

      it('is set to true when the grade is cleared', () => {
        expect(parseValue('').valid).toBe(true)
      })

      it('is set to false when the value is "EX"', () => {
        expect(parseValue('EX').valid).toBe(false)
      })

      it('is set to false when given non-numerical string not in the grading scheme', () => {
        expect(parseValue('B-').valid).toBe(false)
      })

      describe('when not using a grading scheme', () => {
        beforeEach(() => {
          options.gradingScheme = null
        })

        it('is set to true when given a number', () => {
          expect(parseValue('81.45').valid).toBe(true)
        })

        it('is set to true when given a percentage', () => {
          expect(parseValue('81.45%').valid).toBe(true)
        })

        it('is set to false when given a non-numerical value', () => {
          expect(parseValue('B').valid).toBe(false)
        })
      })
    })
  })

  describe('#gradeInfoFromGrade()', () => {
    function gradeInfoFromGrade(grade) {
      return new GradeOverrideEntry(options).gradeInfoFromGrade(grade)
    }

    describe('.grade', () => {
      it('is set to null when the given grade is null', () => {
        expect(gradeInfoFromGrade(null).grade).toEqual(null)
      })

      it('is set to null when the given grade percentage is null', () => {
        expect(gradeInfoFromGrade({percentage: null}).grade).toEqual(null)
      })

      describe('.percentage', () => {
        it('is set to the given grade percentage', () => {
          expect(gradeInfoFromGrade({percentage: 81.1234}).grade?.percentage).toEqual(81.1234)
        })
      })

      describe('.schemeKey', () => {
        it('is set to the scheme key matching the given grade percentage', () => {
          expect(
            gradeInfoFromGrade({percentage: 81.1234, schemeKey: 'B'}).grade?.schemeKey
          ).toEqual('B')
        })

        it('is set to null when not using a grading scheme', () => {
          options.gradingScheme = null
          expect(gradeInfoFromGrade({percentage: 81.1234}).grade?.schemeKey).toEqual(null)
        })
      })
    })

    describe('.enteredAs', () => {
      const {PERCENTAGE} = EnterGradesAs

      it(`is set to "${PERCENTAGE}" when using a grading scheme`, () => {
        expect(gradeInfoFromGrade({percentage: 81.1234, schemeKey: 'B'}).enteredAs).toEqual(
          PERCENTAGE
        )
      })

      it(`is set to "${PERCENTAGE}" when not using a grading scheme`, () => {
        options.gradingScheme = null
        expect(gradeInfoFromGrade({percentage: 81.1234}).enteredAs).toEqual(PERCENTAGE)
      })

      it('is set to null when the given grade is null', () => {
        expect(gradeInfoFromGrade(null).enteredAs).toEqual(null)
      })

      it('is set to null when the given grade percentage is null', () => {
        expect(gradeInfoFromGrade({percentage: null}).enteredAs).toEqual(null)
      })
    })

    describe('.valid', () => {
      it('is set to true when the grade percentage is a valid number', () => {
        expect(gradeInfoFromGrade({percentage: 81.2345}).valid).toBe(true)
      })

      it('is set to true when the grade is null', () => {
        expect(gradeInfoFromGrade(null).valid).toBe(true)
      })

      it('is set to true when the grade percentage is null', () => {
        expect(gradeInfoFromGrade({percentage: null}).valid).toBe(true)
      })

      describe('when using a grading scheme', () => {
        it('is set to true when the grade scheme key is in the grading scheme', () => {
          expect(gradeInfoFromGrade({schemeKey: 'B'}).valid).toBe(true)
        })

        it('is set to false when the grade scheme key is not in the grading scheme', () => {
          expect(gradeInfoFromGrade({schemeKey: 'B-'}).valid).toBe(false)
        })

        it('is set to true when the scheme is a points based grading scheme and the user inputs a percentage and returns the percentage and schemeKey', () => {
          const gradeEntryOptions = {
            gradingScheme: {
              data: [
                ['A', 0.9],
                ['B', 0.8],
                ['C', 0.7],
                ['D', 0.6],
                ['F', 0.5],
              ],
              id: 'some-id',
              pointsBased: true,
              scalingFactor: 4.0,
              title: 'A Points Based Grading Scheme',
            },
          }

          const gradeOverrideEntry = new GradeOverrideEntry(gradeEntryOptions)
          const res = gradeOverrideEntry.gradeInfoFromGrade({percentage: '75%'}, true)
          expect(res.valid).toBe(true)
          expect(res.enteredAs).toBe(EnterGradesAs.PERCENTAGE)
          expect(res.grade?.percentage).toBe(75)
          expect(res.grade?.schemeKey).toBe('C')
        })

        it('is set to true when the scheme is a points based grading scheme and the persisted override is a percent', () => {
          // note that the server always saves the override as a percentage, so this test is necessary to ensure initial rendering doesn't result in validation errors
          const gradeEntryOptions = {
            gradingScheme: {
              data: [
                ['A', 0.9],
                ['B', 0.8],
                ['C', 0.7],
                ['D', 0.6],
                ['F', 0.5],
              ],
              id: 'some-id',
              pointsBased: true,
              scalingFactor: 4.0,
              title: 'A Points Based Grading Scheme',
            },
          }

          const gradeOverrideEntry = new GradeOverrideEntry(gradeEntryOptions)
          const res = gradeOverrideEntry.gradeInfoFromGrade({percentage: 80}, false)
          expect(res.valid).toBe(true)
          expect(res.enteredAs).toBe(EnterGradesAs.PERCENTAGE)
          expect(res.grade?.percentage).toBe(80)
          expect(res.grade?.schemeKey).toBe('B')
        })
      })
    })
  })
})
