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
import StudentDatastore from 'jsx/gradezilla/default_gradebook/stores/StudentDatastore'

QUnit.module('StudentDatastore', function(hooks) {
  let studentDatastore
  let userStudentMap
  let testStudentMap

  hooks.beforeEach(function() {
    userStudentMap = {}
    testStudentMap = {}
    studentDatastore = new StudentDatastore(userStudentMap, testStudentMap)
  })

  QUnit.module('#listStudentIds')

  test('returns the definitive list of known students', function() {
    const studentIds = ['1101', '1102', '1103']
    studentDatastore.setStudentIds(studentIds)
    const storedStudentIds = studentDatastore.listStudentIds()
    strictEqual(storedStudentIds.length, 3, 'datastore contains 3 students')
    deepEqual(storedStudentIds, studentIds)
  })

  QUnit.module('#setStudentIds')

  test('removes stored user students not represented in the list of student ids', function() {
    const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
    studentDatastore.addUserStudents(students)
    studentDatastore.setStudentIds(['1102'])
    const storedStudents = studentDatastore.listStudents()
    strictEqual(storedStudents.length, 1, 'datastore contains 1 student')
    equal(storedStudents[0].id, '1102')
  })

  test('removes stored test students not represented in the list of student ids', function() {
    const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
    studentDatastore.addTestStudents(students)
    studentDatastore.setStudentIds(['1102'])
    const storedStudents = studentDatastore.listStudents()
    strictEqual(storedStudents.length, 1, 'datastore contains 1 student')
    equal(storedStudents[0].id, '1102')
  })

  QUnit.module('#listStudents')

  test('returns the students stored in order of the saved student ids', function() {
    const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
    studentDatastore.addUserStudents(students)
    studentDatastore.setStudentIds(['1101', '1102', '1103'])
    const storedStudents = studentDatastore.listStudents()
    strictEqual(storedStudents.length, 3, 'datastore contains 3 students')
    deepEqual(storedStudents, _.sortBy(students, 'id'))
  })

  test('includes test students', function() {
    const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
    studentDatastore.addUserStudents(students.slice(0, 2))
    studentDatastore.addTestStudents(students.slice(2, 3))
    studentDatastore.setStudentIds(['1101', '1102', '1103'])
    const storedStudents = studentDatastore.listStudents()
    strictEqual(storedStudents.length, 3, 'datastore contains 3 students')
    deepEqual(storedStudents, _.sortBy(students, 'id'))
  })

  test('includes students stored directly into the original userStudentMap', function() {
    studentDatastore.setStudentIds(['1101', '1102', '1103'])
    const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
    Object.assign(userStudentMap, _.keyBy(students, 'id'))
    const storedStudents = studentDatastore.listStudents()
    strictEqual(storedStudents.length, 3, 'datastore contains 3 students')
    deepEqual(storedStudents, _.sortBy(students, 'id'))
  })

  test('includes students stored directly into the original testStudentMap', function() {
    studentDatastore.setStudentIds(['1101', '1102', '1103'])
    const students = [{id: '1103'}, {id: '1101'}, {id: '1102'}]
    Object.assign(testStudentMap, _.keyBy(students, 'id'))
    const storedStudents = studentDatastore.listStudents()
    strictEqual(storedStudents.length, 3, 'datastore contains 3 students')
    deepEqual(storedStudents, _.sortBy(students, 'id'))
  })

  test('includes placeholder students for student ids not matching a stored student object', function() {
    const students = [{id: '1103'}, {id: '1101'}]
    studentDatastore.addUserStudents(students)
    studentDatastore.setStudentIds(['1101', '1102', '1103'])
    const placeholderStudent = studentDatastore
      .listStudents()
      .find(student => student.id === '1102')
    strictEqual(placeholderStudent.isPlaceholder, true)
  })
})
