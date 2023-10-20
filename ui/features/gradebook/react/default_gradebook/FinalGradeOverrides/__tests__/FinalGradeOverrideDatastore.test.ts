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

import GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'
import FinalGradeOverrideDatastore from '../FinalGradeOverrideDatastore'
import useStore from '../../stores'

describe('Gradebook FinalGradeOverrideDatastore', () => {
  let datastore

  beforeEach(() => {
    datastore = new FinalGradeOverrideDatastore()
  })

  describe('#getGrade()', () => {
    let grades

    beforeEach(() => {
      grades = {
        1101: {
          courseGrade: {
            percentage: 90.12,
          },
          gradingPeriodGrades: {
            1502: {
              percentage: 81.23,
            },
          },
        },

        1102: {
          gradingPeriodGrades: {
            1501: {
              percentage: 81.23,
            },
          },
        },
      }

      datastore.setGrades(grades)
    })

    it('returns the course grade when given a null grading period id', () => {
      expect(datastore.getGrade('1101', null)).toEqual({percentage: 90.12})
    })

    it('returns null for course grade when the given user has no course grade override', () => {
      expect(datastore.getGrade('1102', null)).toBe(null)
    })

    it('returns the related grading period grade when given a grading period id', () => {
      expect(datastore.getGrade('1102', '1501')).toEqual({percentage: 81.23})
    })

    it('returns null for grading period grade when the given user has no related override', () => {
      expect(datastore.getGrade('1101', '1501')).toBe(null)
    })

    it('returns null for grading period grade when the given user has no grading period overrides', () => {
      delete grades[1101].gradingPeriodGrades
      expect(datastore.getGrade('1101', '1501')).toBe(null)
    })

    it('returns null for course grade when the given user has no overrides', () => {
      expect(datastore.getGrade('1103', null)).toBe(null)
    })

    it('returns null for grading period grade when the given user has no overrides', () => {
      expect(datastore.getGrade('1103', '1501')).toBe(null)
    })
  })

  describe('#updateGrade()', () => {
    let grades

    beforeEach(() => {
      grades = {
        1101: {
          courseGrade: {
            percentage: 90.12,
          },
        },

        1102: {
          gradingPeriodGrades: {
            1501: {
              percentage: 81.23,
            },
          },
        },
      }

      datastore.setGrades(grades)

      useStore.setState({
        finalGradeOverrides: {
          1101: {
            courseGrade: {
              percentage: 90.12,
            },
          },
          1102: {
            gradingPeriodGrades: {
              1501: {
                percentage: 81.23,
              },
            },
          },
        },
      })
    })

    it('updates the course grade when given a null grading period id', () => {
      datastore.updateGrade('1101', null, {percentage: 91})
      expect(datastore.getGrade('1101', null)).toEqual({percentage: 91})
    })

    it('adds the course grade when the given user has no course grade override', () => {
      datastore.updateGrade('1102', null, {percentage: 91})
      expect(datastore.getGrade('1102', null)).toEqual({percentage: 91})
    })

    it('updates the grading period grade when given a grading period id', () => {
      datastore.updateGrade('1102', '1501', {percentage: 82})
      expect(datastore.getGrade('1102', '1501')).toEqual({percentage: 82})
    })

    it('adds the grading period grade when the given user has no override for the given grading period', () => {
      datastore.updateGrade('1102', '1502', {percentage: 82})
      expect(datastore.getGrade('1102', '1502')).toEqual({percentage: 82})
    })

    it('adds the grading period grade when the given user has no grading period overrides', () => {
      datastore.updateGrade('1101', '1501', {percentage: 82})
      expect(datastore.getGrade('1101', '1501')).toEqual({percentage: 82})
    })

    it('adds the course grade when the given user has no overrides', () => {
      datastore.updateGrade('1103', null, {percentage: 91})
      expect(datastore.getGrade('1103', null)).toEqual({percentage: 91})
    })

    it('adds the grading period grade when the given user has no overrides', () => {
      datastore.updateGrade('1103', '1501', {percentage: 82})
      expect(datastore.getGrade('1103', '1501')).toEqual({percentage: 82})
    })

    it('updates store finalGradesOverride value for the student', () => {
      datastore.updateGrade('1101', null, {percentage: 91})
      expect(datastore.getGrade('1101', null)).toEqual({percentage: 91})
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      const studentOverrides = updatedFinalGradeOverrides['1101']
      expect(studentOverrides.courseGrade?.percentage).toEqual(91)
    })

    it('updates store finalGradesOverride value for the student with grading period', () => {
      datastore.updateGrade('1101', '1501', {percentage: 91})
      expect(datastore.getGrade('1101', '1501')).toEqual({percentage: 91})
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      const studentOverrides = updatedFinalGradeOverrides['1101']
      expect(studentOverrides.gradingPeriodGrades['1501']?.percentage).toEqual(91)
    })

    it('only updates store finalGradesOverride for the student changed', () => {
      datastore.updateGrade('1101', '1501', {percentage: 91})
      expect(datastore.getGrade('1101', '1501')).toEqual({percentage: 91})
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      const studentOverrides = updatedFinalGradeOverrides['1102']
      expect(studentOverrides.gradingPeriodGrades['1501']?.percentage).toEqual(81.23)
    })
  })

  describe('#addPendingGradeInfo()', () => {
    describe('when adding course grade override info', () => {
      it('adds the info when the given user has no pending course grade override', () => {
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', null, gradeInfo)
        expect(datastore.getPendingGradeInfo('1101', null)).toBe(gradeInfo)
      })

      it('replaces the existing pending course grade override for the given user', () => {
        const previousGradeInfo = new GradeOverrideInfo()
        const nextGradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', null, previousGradeInfo)
        datastore.addPendingGradeInfo('1101', null, nextGradeInfo)
        expect(datastore.getPendingGradeInfo('1101', null)).toBe(nextGradeInfo)
      })

      it('does not replace pending course grade overrides for other users', () => {
        const otherUserInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1102', null, otherUserInfo)
        datastore.addPendingGradeInfo('1101', null, gradeInfo)
        expect(datastore.getPendingGradeInfo('1102', null)).toBe(otherUserInfo)
      })

      it('does not replace pending grading period overrides for the same user', () => {
        const gradingPeriodInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', '1501', gradingPeriodInfo)
        datastore.addPendingGradeInfo('1101', null, gradeInfo)
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(gradingPeriodInfo)
      })
    })

    describe('when adding grading period override info', () => {
      it('adds the info when the given user has no pending grading period override', () => {
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', '1501', gradeInfo)
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(gradeInfo)
      })

      it('replaces the existing pending grading period override for the given user', () => {
        const previousGradeInfo = new GradeOverrideInfo()
        const nextGradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', '1501', previousGradeInfo)
        datastore.addPendingGradeInfo('1101', '1501', nextGradeInfo)
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(nextGradeInfo)
      })

      it('does not replace pending grading period overrides for other users', () => {
        const otherUserInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1102', '1501', otherUserInfo)
        datastore.addPendingGradeInfo('1101', '1501', gradeInfo)
        expect(datastore.getPendingGradeInfo('1102', '1501')).toBe(otherUserInfo)
      })

      it('does not replace pending grading period overrides for other grading periods', () => {
        const otherPeriodInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', '1501', otherPeriodInfo)
        datastore.addPendingGradeInfo('1101', '1502', gradeInfo)
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(otherPeriodInfo)
      })

      it('does not replace a pending course grade override for the same user', () => {
        const courseGradeInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', null, courseGradeInfo)
        datastore.addPendingGradeInfo('1101', '1501', gradeInfo)
        expect(datastore.getPendingGradeInfo('1101', null)).toBe(courseGradeInfo)
      })
    })
  })

  describe('#removePendingGradeInfo()', () => {
    describe('when removing course grade override info', () => {
      it('removes the pending course grade override for the given user', () => {
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', null, gradeInfo)
        datastore.removePendingGradeInfo('1101', null)
        expect(datastore.getPendingGradeInfo('1101', null)).toBe(null)
      })

      it('has no effect when the given user has no pending course grade override', () => {
        datastore.removePendingGradeInfo('1101', null)
        expect(datastore.getPendingGradeInfo('1101', null)).toBe(null)
      })

      it('does not remove pending course grade overrides for other users', () => {
        const otherUserInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1102', null, otherUserInfo)
        datastore.addPendingGradeInfo('1101', null, gradeInfo)
        datastore.removePendingGradeInfo('1101', null)
        expect(datastore.getPendingGradeInfo('1102', null)).toBe(otherUserInfo)
      })

      it('does not remove pending grading period overrides for the same user', () => {
        const gradingPeriodInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', '1501', gradingPeriodInfo)
        datastore.addPendingGradeInfo('1101', null, gradeInfo)
        datastore.removePendingGradeInfo('1101', null)
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(gradingPeriodInfo)
      })
    })

    describe('when removing grading period override info', () => {
      it('removes the existing pending grading period override for the given user', () => {
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', '1501', gradeInfo)
        datastore.removePendingGradeInfo('1101', '1501')
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(null)
      })

      it('has no effect when the given user has no pending grading period override', () => {
        datastore.removePendingGradeInfo('1101', '1501')
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(null)
      })

      it('does not remove pending grading period overrides for other users', () => {
        const otherUserInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1102', '1501', otherUserInfo)
        datastore.addPendingGradeInfo('1101', '1501', gradeInfo)
        datastore.removePendingGradeInfo('1101', '1501')
        expect(datastore.getPendingGradeInfo('1102', '1501')).toBe(otherUserInfo)
      })

      it('does not remove pending grading period overrides for other grading periods', () => {
        const otherPeriodInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', '1501', otherPeriodInfo)
        datastore.addPendingGradeInfo('1101', '1502', gradeInfo)
        datastore.removePendingGradeInfo('1101', '1502')
        expect(datastore.getPendingGradeInfo('1101', '1501')).toBe(otherPeriodInfo)
      })

      it('does not remove a pending course grade override for the same user', () => {
        const courseGradeInfo = new GradeOverrideInfo()
        const gradeInfo = new GradeOverrideInfo()
        datastore.addPendingGradeInfo('1101', null, courseGradeInfo)
        datastore.addPendingGradeInfo('1101', '1501', gradeInfo)
        datastore.removePendingGradeInfo('1101', '1501')
        expect(datastore.getPendingGradeInfo('1101', null)).toBe(courseGradeInfo)
      })
    })
  })
})
