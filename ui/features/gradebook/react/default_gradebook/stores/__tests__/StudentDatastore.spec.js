/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import _ from 'lodash'
import StudentDatastore from '../StudentDatastore'

describe('StudentDatastore', () => {
  let studentDatastore
  let userStudentMap
  let testStudentMap

  beforeEach(() => {
    userStudentMap = {}
    testStudentMap = {}
    studentDatastore = new StudentDatastore(userStudentMap, testStudentMap)
  })

  describe('#listStudentIds', () => {
    test('returns the definitive list of known students', () => {
      const studentIds = ['1101', '1102', '1103']
      studentDatastore.setStudentIds(studentIds)
      const storedStudentIds = studentDatastore.listStudentIds()
      expect(storedStudentIds.length).toBe(3)
      expect(storedStudentIds).toEqual(studentIds)
    })
  })

  describe('#setStudentIds', () => {
    test('removes stored user students not represented in the list of student ids', () => {
      const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
      studentDatastore.addUserStudents(students)
      studentDatastore.setStudentIds(['1102'])
      const storedStudents = studentDatastore.listStudents()
      expect(storedStudents.length).toBe(1)
      expect(storedStudents[0].id).toBe('1102')
    })

    test('removes stored test students not represented in the list of student ids', () => {
      const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
      studentDatastore.addTestStudents(students)
      studentDatastore.setStudentIds(['1102'])
      const storedStudents = studentDatastore.listStudents()
      expect(storedStudents.length).toBe(1)
      expect(storedStudents[0].id).toBe('1102')
    })
  })

  describe('#listStudents', () => {
    test('returns the students stored in order of the saved student ids', () => {
      const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
      studentDatastore.addUserStudents(students)
      studentDatastore.setStudentIds(['1101', '1102', '1103'])
      const storedStudents = studentDatastore.listStudents()
      expect(storedStudents.length).toBe(3)
      expect(storedStudents).toEqual(_.sortBy(students, 'id'))
    })

    test('includes test students', () => {
      const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
      studentDatastore.addUserStudents(students.slice(0, 2))
      studentDatastore.addTestStudents(students.slice(2, 3))
      studentDatastore.setStudentIds(['1101', '1102', '1103'])
      const storedStudents = studentDatastore.listStudents()
      expect(storedStudents.length).toBe(3)
      expect(storedStudents).toEqual(_.sortBy(students, 'id'))
    })

    test('includes students stored directly into the original userStudentMap', () => {
      studentDatastore.setStudentIds(['1101', '1102', '1103'])
      const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
      Object.assign(userStudentMap, _.keyBy(students, 'id'))
      const storedStudents = studentDatastore.listStudents()
      expect(storedStudents.length).toBe(3)
      expect(storedStudents).toEqual(_.sortBy(students, 'id'))
    })

    test('includes students stored directly into the original testStudentMap', () => {
      studentDatastore.setStudentIds(['1101', '1102', '1103'])
      const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
      Object.assign(testStudentMap, _.keyBy(students, 'id'))
      const storedStudents = studentDatastore.listStudents()
      expect(storedStudents.length).toBe(3)
      expect(storedStudents).toEqual(_.sortBy(students, 'id'))
    })

    test('includes placeholder students for student ids not matching a stored student object', () => {
      const students = [{id: '1103'}, {id: '1101'}]
      studentDatastore.addUserStudents(students)
      studentDatastore.setStudentIds(['1101', '1102', '1103'])
      const placeholderStudent = studentDatastore
        .listStudents()
        .find(student => student.id === '1102')
      expect(placeholderStudent.isPlaceholder).toBe(true)
    })

    test('optionally excludes placeholder students', () => {
      const students = [{id: '1103'}, {id: '1101'}]
      studentDatastore.addUserStudents(students)
      studentDatastore.setStudentIds(['1101', '1102', '1103'])
      const placeholderStudent = studentDatastore
        .listStudents({includePlaceholders: false})
        .find(student => student.id === '1102')
      expect(placeholderStudent).toBeUndefined()
    })
  })

  describe('#student', () => {
    beforeEach(() => {
      studentDatastore.addUserStudents([
        {id: '1103', name: 'John Doe'},
        {id: '1101', name: 'Jane Doe'},
      ])
    })

    test('fetches the student by id', () => {
      expect(studentDatastore.student('1103').name).toBe('John Doe')
    })

    test('returns test students', () => {
      studentDatastore.addTestStudents([{id: '1803', name: 'Test Student'}])
      expect(studentDatastore.student('1803').name).toBe('Test Student')
    })

    test('returns a placeholder student when not found', () => {
      expect(studentDatastore.student('1104').isPlaceholder).toBe(true)
    })

    test('optionally returns undefined when student not found', () => {
      expect(studentDatastore.student('1104', {includePlaceholder: false})).toBeUndefined()
    })
  })
})
