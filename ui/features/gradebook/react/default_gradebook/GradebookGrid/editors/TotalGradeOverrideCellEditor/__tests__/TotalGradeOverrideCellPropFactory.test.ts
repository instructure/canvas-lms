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

import sinon from 'sinon'

import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'
import FinalGradeOverrides from '../../../../FinalGradeOverrides/index'
import TotalGradeOverrideCellPropFactory from '../TotalGradeOverrideCellPropFactory'
import type {DeprecatedGradingScheme} from '@canvas/grading/grading.d'
import useStore from '../../../../stores'

const mockTotalGradeOverrideStore = (state = {}) => {
  jest.spyOn(useStore, 'getState').mockImplementation(() => {
    return {
      finalGradeOverrideTrayProps: {
        isFirstStudent: false,
        isLastStudent: false,
        studentInfo: {
          id: '1',
          avatarUrl: 'https://canvas.instructure.com/images/messages/avatar-50.png',
          name: 'Student, Test',
          gradesUrl: 'https://canvas.instructure.com/courses/1/grades#tab-assignments',
          enrollmentId: '222',
        },
        isOpen: false,
      },
      finalGradeOverrides: {
        1101: {
          courseGrade: {
            percentage: 88.1,
            customGradeStatusId: '1',
          },
          gradingPeriodGrades: {
            10: {
              percentage: 99,
              customGradeStatusId: '1',
            },
          },
        },
      },
      ...state,
    }
  })

  return jest.spyOn(useStore, 'setState')
}

describe('GradebookGrid TotalGradeOverrideCellPropFactory', () => {
  let gradebook
  let gradingScheme: DeprecatedGradingScheme

  describe('#getProps()', () => {
    let editorOptions

    beforeEach(() => {
      gradingScheme = {
        data: [
          ['A', 0.9],
          ['B', 0.8],
          ['C', 0.7],
          ['D', 0.6],
          ['F', 0.5],
        ],
        id: '2801',
        title: 'Default Grading Scheme',
        pointsBased: false,
        scalingFactor: 1.0,
      }

      // `gradebook` is a double because CoffeeScript and AMD cannot be imported
      // into Jest specs
      gradebook = {
        getCourseGradingScheme() {
          return gradingScheme
        },

        gradebookGrid: {
          updateRowCell: sinon.stub(),
        },

        isFilteringColumnsByGradingPeriod: sinon.stub().returns(false),

        studentCanReceiveGradeOverride(id) {
          return {1101: true, 1102: false}[id]
        },

        gridData: {
          rows: [{}, {}],
        },

        options: {
          custom_grade_statuses_enabled: false,
        },
      }

      gradebook.finalGradeOverrides = new FinalGradeOverrides(gradebook)
      gradebook.finalGradeOverrides.setGrades({
        1101: {
          courseGrade: {
            percentage: 88.1,
          },
        },
      })

      editorOptions = {
        item: {
          id: '1101',
          name: 'Some Student',
          avatar_url: 'https://canvas.instructure.com/images/messages/avatar-55.png',
          enrollments: [
            {
              id: '222',
              grades: {
                html_url: 'https://canvas.instructure.com/courses/1101/grades',
              },
            },
          ],
        },
        activeRow: 1,
      }
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    function getProps() {
      const factory = new TotalGradeOverrideCellPropFactory(gradebook)
      return factory.getProps(editorOptions)
    }

    it('sets .gradeEntry to a GradeOverrideEntry instance', () => {
      expect(getProps().gradeEntry).toBeInstanceOf(GradeOverrideEntry)
    })

    it('uses the grading scheme from the Gradebook to create the GradeEntry', () => {
      expect(getProps().gradeEntry.gradingScheme).toBe(gradingScheme)
    })

    it('sets .gradeInfo to a GradeOverrideInfo instance', () => {
      expect(getProps().gradeInfo).toBeInstanceOf(GradeOverrideInfo)
    })

    it('derives the grade override info from the user grade', () => {
      expect(getProps().gradeInfo.grade.percentage).toEqual(88.1)
    })

    it('sets .gradeIsUpdating to false when the user does not have a pending grade', () => {
      expect(getProps().gradeIsUpdating).toBe(false)
    })

    it('sets .gradeIsUpdating to true when the user has a valid pending grade', () => {
      const {gradeEntry} = getProps()
      const gradeInfo = gradeEntry.parseValue('A')
      gradebook.finalGradeOverrides._datastore.addPendingGradeInfo('1101', null, gradeInfo)
      expect(getProps().gradeIsUpdating).toBe(true)
    })

    it('sets .gradeIsUpdating to false when the user has an invalid pending grade', () => {
      const {gradeEntry} = getProps()
      const gradeInfo = gradeEntry.parseValue('invalid')
      gradebook.finalGradeOverrides._datastore.addPendingGradeInfo('1101', null, gradeInfo)
      expect(getProps().gradeIsUpdating).toBe(false)
    })

    describe('.onGradeUpdate', () => {
      let props

      beforeEach(() => {
        sinon.stub(gradebook.finalGradeOverrides, 'updateGrade')
        props = getProps()
      })

      it('updates a final grade override when called', () => {
        const gradeInfo = props.gradeEntry.parseValue('A')
        props.onGradeUpdate(gradeInfo)
        expect(gradebook.finalGradeOverrides.updateGrade.callCount).toEqual(1)
      })

      it('includes the user id for the row when updating the final grade override', () => {
        const gradeInfo = props.gradeEntry.parseValue('A')
        props.onGradeUpdate(gradeInfo)
        const [userId] = gradebook.finalGradeOverrides.updateGrade.lastCall.args
        expect(userId).toEqual('1101')
      })

      it('includes the given grade override info when updating the final grade override', () => {
        const gradeInfo = props.gradeEntry.parseValue('A')
        props.onGradeUpdate(gradeInfo)
        const [, gradeOverrideInfo] = gradebook.finalGradeOverrides.updateGrade.lastCall.args
        expect(gradeOverrideInfo).toBe(gradeInfo)
      })
    })

    it('sets .pendingGradeInfo to the pending grade for the related user', () => {
      const {gradeEntry} = getProps()
      const gradeInfo = gradeEntry.parseValue('A')
      gradebook.finalGradeOverrides._datastore.addPendingGradeInfo('1101', null, gradeInfo)
      expect(getProps().pendingGradeInfo).toBe(gradeInfo)
    })

    it('sets .studentIsGradeable to true when the student is gradeable', () => {
      expect(getProps().studentIsGradeable).toBe(true)
    })

    it('sets .studentIsGradeable to false when the student is not gradeable', () => {
      editorOptions.item.id = '1102'
      expect(getProps().studentIsGradeable).toBe(false)
    })

    describe('finalGradeOverrideTrayProps state', () => {
      it('correctly sets finalGradeOverrideTrayProps state', () => {
        const mockSetState = mockTotalGradeOverrideStore()
        const {gradeEntry} = getProps()
        expect(mockSetState).toHaveBeenLastCalledWith({
          finalGradeOverrideTrayProps: {
            isFirstStudent: false,
            isLastStudent: true,
            studentInfo: {
              id: '1101',
              avatarUrl: 'https://canvas.instructure.com/images/messages/avatar-55.png',
              name: 'Some Student',
              gradesUrl: 'https://canvas.instructure.com/courses/1101/grades#tab-assignments',
              enrollmentId: '222',
            },
            isOpen: false,
            gradeEntry,
          },
        })
      })
    })

    describe('disabledByCustomStatus', () => {
      it('correctly sets disabledByCustomStatus to true when a user has a custom status with allow_final_grade_value set to false', () => {
        mockTotalGradeOverrideStore()
        gradebook.options.custom_grade_statuses_enabled = true
        gradebook.options.custom_grade_statuses = [
          {
            id: '1',
            title: 'Custom Status',
            allow_final_grade_value: false,
          },
        ]
        expect(getProps().disabledByCustomStatus).toBe(true)
      })

      it('correctly sets disabledByCustomStatus to false when a user has a custom status with allow_final_grade_value set to true', () => {
        mockTotalGradeOverrideStore()
        gradebook.options.custom_grade_statuses_enabled = true
        gradebook.options.custom_grade_statuses = [
          {
            id: '1',
            title: 'Custom Status',
            allow_final_grade_value: true,
          },
        ]
        expect(getProps().disabledByCustomStatus).toBe(false)
      })

      it('correctly sets disabledByCustomStatus to false when a user does not have a custom status', () => {
        mockTotalGradeOverrideStore({finalGradeOverrides: {1101: {}}})
        gradebook.options.custom_grade_statuses_enabled = true
        gradebook.options.custom_grade_statuses = [
          {
            id: '1',
            title: 'Custom Status',
            allow_final_grade_value: false,
          },
        ]
        expect(getProps().disabledByCustomStatus).toBe(false)
      })

      it('correctly sets disabledByCustomStatus to true for a grading period', () => {
        mockTotalGradeOverrideStore()
        gradebook.options.custom_grade_statuses_enabled = true
        gradebook.options.custom_grade_statuses = [
          {
            id: '1',
            title: 'Custom Status',
            allow_final_grade_value: false,
          },
        ]
        gradebook.gradingPeriodId = '10'
        expect(getProps().disabledByCustomStatus).toBe(true)
      })
    })
  })
})
