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

import * as GradeActions from '../GradeActions'
import configureStore from '../../configureStore'

describe('GradeSummary gradesReducer()', () => {
  let store
  let provisionalGrades

  beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        id: '2301',
        title: 'Example Assignment',
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'},
        {graderId: '1103', graderName: 'Mrs. Krabappel'},
        {graderId: '1104', graderName: 'Mr. Feeny'},
      ],
    })

    provisionalGrades = [
      {
        grade: 'A',
        graderId: '1101',
        id: '4601',
        score: 10,
        selected: true,
        studentId: '1111',
      },
      {
        grade: 'B',
        graderId: '1102',
        id: '4602',
        score: 9,
        selected: false,
        studentId: '1112',
      },
      {
        grade: 'C',
        graderId: '1102',
        id: '4603',
        score: 8,
        selected: false,
        studentId: '1111',
      },
      {
        grade: 'C',
        graderId: '1103',
        id: '4604',
        score: 8,
        selected: false,
        studentId: '1113',
      },
    ]
  })

  function getProvisionalGrades() {
    return store.getState().grades.provisionalGrades
  }

  function getBulkSelectionDetails(graderId) {
    return store.getState().grades.bulkSelectionDetails[graderId]
  }

  describe('when handling "ADD_PROVISIONAL_GRADES"', () => {
    test('adds a key for each student among the provisional grades', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      expect(Object.keys(getProvisionalGrades()).sort()).toEqual(['1111', '1112', '1113'])
    })

    test('adds a key to a student for each grader who graded that student', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      expect(Object.keys(getProvisionalGrades()[1111]).sort()).toEqual(['1101', '1102'])
    })

    test('does not add a key to a student for a grader who has not graded that student', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      expect(Object.keys(getProvisionalGrades()[1112])).toEqual(['1102'])
    })

    test('keys a grade to the grader id within the student map', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      expect(getProvisionalGrades()[1112][1102]).toEqual(provisionalGrades[1])
    })

    test('does not key a grade to the grader id if the grade is null', () => {
      provisionalGrades[2].grade = null
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      expect(getProvisionalGrades()[1111][1102]).toBeUndefined()
    })

    test('updates .bulkSelectionDetails', () => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
      expect(getBulkSelectionDetails(1103).provisionalGradeIds).toEqual(['4604'])
    })
  })

  describe('when handling "SET_SELECTED_PROVISIONAL_GRADE"', () => {
    beforeEach(() => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
    })

    test('sets the given provisional grade as selected', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      expect(getProvisionalGrades()[1111][1102].selected).toBe(true)
    })

    test('sets the previously-selected provisional grade as not selected', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      expect(getProvisionalGrades()[1111][1101].selected).toBe(false)
    })

    test('replaces the instance of the given provisional grade', () => {
      const grade = getProvisionalGrades()[1111][1102]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(grade))
      expect(getProvisionalGrades()[1111][1102]).not.toBe(grade)
    })

    test('replaces the instance of the de-selected provisional grade', () => {
      const grade = getProvisionalGrades()[1111][1101]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      expect(getProvisionalGrades()[1111][1101]).not.toBe(grade)
    })

    test('does not replace instances of related grades not previously selected', () => {
      const grade = getProvisionalGrades()[1111][1101]
      grade.selected = false
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      expect(getProvisionalGrades()[1111][1101]).toBe(grade)
    })

    test('replaces the instance of student grades collection', () => {
      const grades = getProvisionalGrades()[1111]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      expect(getProvisionalGrades()[1111]).not.toBe(grades)
    })

    test('does not replace instances of unrelated student grades collections', () => {
      const grades = getProvisionalGrades()[1112]
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      expect(getProvisionalGrades()[1112]).toBe(grades)
    })

    test('replaces the provisional grades instance', () => {
      const grades = getProvisionalGrades()
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[2]))
      expect(getProvisionalGrades()).not.toBe(grades)
    })

    test('updates .bulkSelectionDetails', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrade(provisionalGrades[3]))
      expect(getBulkSelectionDetails(1103).provisionalGradeIds).toEqual([])
    })
  })

  describe('when handling "SET_SELECTED_PROVISIONAL_GRADES"', () => {
    beforeEach(() => {
      store.dispatch(GradeActions.addProvisionalGrades(provisionalGrades))
    })

    test('sets the given provisional grades as selected', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()[1111][1102].selected).toBe(true)
    })

    test('sets previously-selected provisional grades for the related students as not selected', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()[1111][1101].selected).toBe(false)
    })

    test('replaces the instance of the related provisional grades', () => {
      const grade = getProvisionalGrades()[1111][1102]
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()[1111][1102]).not.toBe(grade)
    })

    test('replaces the instance of the de-selected provisional grades', () => {
      const grade = getProvisionalGrades()[1111][1101]
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()[1111][1101]).not.toBe(grade)
    })

    test('does not replace instances of related grades not previously selected', () => {
      const grade = getProvisionalGrades()[1111][1101]
      grade.selected = false
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()[1111][1101]).toBe(grade)
    })

    test('replaces the instances of student grades collections', () => {
      const grades = getProvisionalGrades()[1111]
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()[1111]).not.toBe(grades)
    })

    test('does not replace instances of unrelated student grades collections', () => {
      const grades = getProvisionalGrades()[1112]
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()[1112]).toBe(grades)
    })

    test('replaces the provisional grades instance', () => {
      const grades = getProvisionalGrades()
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4603']))
      expect(getProvisionalGrades()).not.toBe(grades)
    })

    test('updates .bulkSelectionDetails', () => {
      store.dispatch(GradeActions.setSelectedProvisionalGrades(['4604']))
      expect(getBulkSelectionDetails(1103).provisionalGradeIds).toEqual([])
    })
  })

  describe('when handling "SET_SELECT_PROVISIONAL_GRADE_STATUS"', () => {
    function setSelectProvisionalGradeStatus(gradeInfo, status) {
      store.dispatch(GradeActions.setSelectProvisionalGradeStatus(gradeInfo, status))
    }

    function getSelectProvisionalGradeStatus(studentId) {
      return store.getState().grades.selectProvisionalGradeStatuses[studentId]
    }

    test('optionally sets the "select provisional grade" status to "failure" for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.FAILURE)
      expect(getSelectProvisionalGradeStatus(1111)).toBe(GradeActions.FAILURE)
    })

    test('optionally sets the "select provisional grade" status to "started" for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.STARTED)
      expect(getSelectProvisionalGradeStatus(1111)).toBe(GradeActions.STARTED)
    })

    test('optionally sets the "select provisional grade" status to "success" for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.SUCCESS)
      expect(getSelectProvisionalGradeStatus(1111)).toBe(GradeActions.SUCCESS)
    })

    test('replaces the previous status for the related student', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.STARTED)
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.SUCCESS)
      expect(getSelectProvisionalGradeStatus(1111)).toBe(GradeActions.SUCCESS)
    })

    test('does not affect unrelated students', () => {
      setSelectProvisionalGradeStatus(provisionalGrades[1], GradeActions.STARTED)
      setSelectProvisionalGradeStatus(provisionalGrades[0], GradeActions.SUCCESS)
      expect(getSelectProvisionalGradeStatus(1112)).toBe(GradeActions.STARTED)
    })
  })

  describe('when updating .bulkSelectionDetails', () => {
    beforeEach(() => {
      provisionalGrades = [
        {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111',
        },
        {
          grade: 'B',
          graderId: '1101',
          id: '4602',
          score: 9,
          selected: false,
          studentId: '1112',
        },
        {
          grade: 'C',
          graderId: '1102',
          id: '4603',
          score: 8,
          selected: false,
          studentId: '1112',
        },
      ]
    })

    function addProvisionalGrades(...ids) {
      const grades = ids.map(id => provisionalGrades.find(grade => grade.id === id))
      store.dispatch(GradeActions.addProvisionalGrades(grades))
    }

    test('includes provisional grades for the related grader', () => {
      addProvisionalGrades('4601', '4602')
      expect(getBulkSelectionDetails(1101).provisionalGradeIds).toEqual(['4601', '4602'])
    })

    test('allows bulk selection for graders who are the only provisional grader for all related students', () => {
      addProvisionalGrades('4601', '4602')
      expect(getBulkSelectionDetails(1101).allowed).toBe(true)
    })

    test('includes no grades for graders who are not the only grader for at least one student', () => {
      addProvisionalGrades('4601', '4602', '4603')
      expect(getBulkSelectionDetails(1101).provisionalGradeIds).toEqual([])
    })

    test('disallows bulk selection for graders who are not the only grader for at least one student', () => {
      addProvisionalGrades('4601', '4602', '4603')
      expect(getBulkSelectionDetails(1101).allowed).toBe(false)
    })

    test('ignores non-provisional graders when checking for multiple graders on students', () => {
      provisionalGrades[2].graderId = '1199' // Use the id of a grader not in the list of provisional graders
      addProvisionalGrades('4601', '4602', '4603')
      expect(getBulkSelectionDetails(1101).provisionalGradeIds).toEqual(['4601', '4602'])
    })

    test('allows bulk selection when only non-provisional graders have also graded related students', () => {
      provisionalGrades[2].graderId = '1199' // Use the id of a grader not in the list of provisional graders
      addProvisionalGrades('4601', '4602', '4603')
      expect(getBulkSelectionDetails(1101).allowed).toBe(true)
    })

    test('excludes grades which have already been selected', () => {
      provisionalGrades[0].selected = true
      addProvisionalGrades('4601', '4602')
      expect(getBulkSelectionDetails(1101).provisionalGradeIds).toEqual(['4602'])
    })

    test('excludes grades for students which have a selected grade from a non-provisional grader', () => {
      provisionalGrades[2].graderId = '1199' // Use the id of a grader not in the list of provisional graders
      provisionalGrades[2].selected = true
      addProvisionalGrades('4601', '4602', '4603')
      expect(getBulkSelectionDetails(1101).provisionalGradeIds).toEqual(['4601'])
    })

    test('allows bulk selection when some grades have already been selected', () => {
      provisionalGrades[0].selected = true
      addProvisionalGrades('4601', '4602')
      expect(getBulkSelectionDetails(1101).allowed).toBe(true)
    })

    test('includes no grades for graders who have no loaded grades', () => {
      // While conceptually not a valid scenario, incremental loading of grades
      // makes this possible.
      addProvisionalGrades('4601', '4602')
      expect(getBulkSelectionDetails(1104).provisionalGradeIds).toEqual([])
    })

    test('does not yet disallow bulk selection for graders who have no loaded grades', () => {
      // For this intermediate state, this attribute is not consumed.
      addProvisionalGrades('4601', '4602')
      expect(getBulkSelectionDetails(1104).allowed).toBe(true)
    })
  })
})
