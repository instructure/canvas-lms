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

function createStudentPlaceholder(id: string) {
  return {
    enrollments: [],
    id,
    isConcluded: false,
    isInactive: false,
    isPlaceholder: true,
    loaded: false,
    sections: []
  }
}

export default class StudentDatastore {
  studentIds = []

  constructor(userStudentMap, testStudentMap) {
    this.userStudentMap = userStudentMap
    this.testStudentMap = testStudentMap
  }

  listStudentIds() {
    return this.studentIds
  }

  setStudentIds(studentIds) {
    this.studentIds = studentIds
    const idsOfStoredStudents = Object.keys(this.userStudentMap)
    _.difference(idsOfStoredStudents, studentIds).forEach(removedStudentId => {
      delete this.userStudentMap[removedStudentId]
    })
    const idsOfStoredTestStudents = Object.keys(this.testStudentMap)
    _.difference(idsOfStoredTestStudents, studentIds).forEach(removedStudentId => {
      delete this.testStudentMap[removedStudentId]
    })
  }

  addUserStudents(students) {
    students.forEach(student => {
      this.userStudentMap[student.id] = student
    })
  }

  addTestStudents(students) {
    students.forEach(student => {
      this.testStudentMap[student.id] = student
    })
  }

  student(id, {includePlaceholder = true} = {}) {
    const user = this.userStudentMap[id] || this.testStudentMap[id]
    if (!user && includePlaceholder) {
      return createStudentPlaceholder(id)
    }

    return user
  }

  listStudents({includePlaceholders = true} = {}) {
    return this.studentIds.reduce((students, id) => {
      const student =
        this.userStudentMap[id] || this.testStudentMap[id] || createStudentPlaceholder(id)
      if (includePlaceholders || !student.isPlaceholder) {
        students.push(student)
      }
      return students
    }, [])
  }
}
