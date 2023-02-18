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
import type {GradebookStudent, GradebookStudentMap} from '../gradebook.d'

function createStudentPlaceholder(id: string) {
  return {
    enrollments: [],
    id,
    isConcluded: false,
    isInactive: false,
    isPlaceholder: true,
    loaded: false,
    sections: [],
  }
}

export default class StudentDatastore {
  studentIds: string[] = []

  userStudentMap: {[studentId: string]: GradebookStudent}

  testStudentMap: {[studentId: string]: GradebookStudent}

  preloadedStudentData: {[studentId: string]: GradebookStudent} = {}

  constructor(userStudentMap: GradebookStudentMap, testStudentMap: GradebookStudentMap) {
    this.userStudentMap = userStudentMap
    this.testStudentMap = testStudentMap
  }

  listStudentIds() {
    return this.studentIds
  }

  setStudentIds(studentIds: string[]) {
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

  preloadStudentData(studentId: string, studentData: GradebookStudent) {
    if (!this.preloadedStudentData[studentId]) {
      this.preloadedStudentData[studentId] = studentData
    } else {
      this.preloadedStudentData[studentId] = {
        ...this.preloadedStudentData[studentId],
        ...studentData,
      }
    }
  }

  addUserStudents(students: GradebookStudent[]) {
    students.forEach(student => {
      this.userStudentMap[student.id] = student
    })
  }

  addTestStudents(students: GradebookStudent[]) {
    students.forEach(student => {
      this.testStudentMap[student.id] = student
    })
  }

  student(id: string, {includePlaceholder = true} = {}) {
    const user = this.userStudentMap[id] || this.testStudentMap[id]
    if (!user && includePlaceholder) {
      return createStudentPlaceholder(id)
    }

    return user
  }

  listStudents({includePlaceholders = true} = {}): GradebookStudent[] {
    return this.studentIds.reduce((students: GradebookStudent[], id: string) => {
      const student =
        this.userStudentMap[id] || this.testStudentMap[id] || createStudentPlaceholder(id)
      if (includePlaceholders || !student.isPlaceholder) {
        students.push(student)
      }
      return students
    }, [])
  }
}
