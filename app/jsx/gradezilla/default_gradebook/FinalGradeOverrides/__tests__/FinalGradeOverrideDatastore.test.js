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

import FinalGradeOverrideDatastore from '../FinalGradeOverrideDatastore'

describe('Gradebook FinalGradeOverrideDatastore', () => {
  let datastore

  beforeEach(() => {
    datastore = new FinalGradeOverrideDatastore()
  })

  describe('.getGrades()', () => {
    let grades

    beforeEach(() => {
      grades = {
        1101: {
          courseGrade: {
            percentage: 90.12
          },
          gradingPeriodGrades: {
            1502: {
              percentage: 81.23
            }
          }
        },

        1102: {
          gradingPeriodGrades: {
            1501: {
              percentage: 81.23
            }
          }
        }
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
})
