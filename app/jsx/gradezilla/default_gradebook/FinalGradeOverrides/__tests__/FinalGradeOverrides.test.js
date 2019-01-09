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

import sinon from 'sinon'

import FinalGradeOverrides from '..'

describe('Gradebook FinalGradeOverrides', () => {
  let finalGradeOverrides
  let gradebook
  let grades

  beforeEach(() => {
    // `gradebook` is a double because CoffeeScript and AMD cannot be imported
    // into Jest specs
    gradebook = {
      getGradingPeriodToShow: sinon.stub().returns('1501'),

      gradebookGrid: {
        updateRowCell: sinon.stub()
      },

      isFilteringColumnsByGradingPeriod: sinon.stub().returns(false)
    }
    finalGradeOverrides = new FinalGradeOverrides(gradebook)
  })

  describe('#getGradeForUser()', () => {
    beforeEach(() => {
      grades = {
        1101: {
          courseGrade: {
            percentage: 88.1
          },

          gradingPeriodGrades: {
            1501: {
              percentage: 91.1
            },

            1502: {
              percentage: 77.6
            }
          }
        }
      }
    })

    it('returns the course grade when Gradebook is not filtering to a grading period', () => {
      finalGradeOverrides.setGrades(grades)
      expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(grades[1101].courseGrade)
    })

    it('returns the related grading period grade when Gradebook is filtering to a grading period', () => {
      gradebook.isFilteringColumnsByGradingPeriod.returns(true)
      finalGradeOverrides.setGrades(grades)
      expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(
        grades[1101].gradingPeriodGrades[1501]
      )
    })
  })

  describe('#setGrades()', () => {
    beforeEach(() => {
      grades = {
        1101: {
          courseGrade: {
            percentage: 88.1
          }
        },
        1102: {
          courseGrade: {
            percentage: 91.1
          }
        }
      }
    })

    it('stores the given final grade overrides in the Gradebook', () => {
      finalGradeOverrides.setGrades(grades)
      expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(grades[1101].courseGrade)
    })

    it('updates row cells for each related student', () => {
      finalGradeOverrides.setGrades(grades)
      expect(gradebook.gradebookGrid.updateRowCell.callCount).toEqual(2)
    })

    it('includes the user id when updating column cells', () => {
      finalGradeOverrides.setGrades(grades)
      const calls = [0, 1].map(index => gradebook.gradebookGrid.updateRowCell.getCall(index))
      const studentIds = calls.map(call => call.args[0])
      expect(studentIds).toEqual(['1101', '1102'])
    })

    it('includes the column id when updating column cells', () => {
      finalGradeOverrides.setGrades(grades)
      const calls = [0, 1].map(index => gradebook.gradebookGrid.updateRowCell.getCall(index))
      const studentIds = calls.map(call => call.args[1])
      expect(studentIds).toEqual(['total_grade_override', 'total_grade_override'])
    })

    it('invalidates grid rows after storing final grade overrides', () => {
      gradebook.gradebookGrid.updateRowCell.callsFake(() => {
        // final grade overrides will have already been updated by this time
        expect(finalGradeOverrides.getGradeForUser('1101')).toEqual(grades[1101].courseGrade)
      })
      finalGradeOverrides.setGrades(grades)
    })
  })
})
