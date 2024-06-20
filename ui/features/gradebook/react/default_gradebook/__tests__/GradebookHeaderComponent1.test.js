/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {createGradebook} from './GradebookSpecHelper'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const equal = (x, y) => expect(x).toBe(y)
const strictEqual = (x, y) => expect(x).toStrictEqual(y)
const deepEqual = (x, y) => expect(x).toEqual(y)

let gradebook

describe('Gradebook React Header Component References', () => {
  beforeEach(function () {
    gradebook = createGradebook()
  })

  test('#setHeaderComponentRef stores a reference by a column id', function () {
    const studentRef = {column: 'student'}
    const totalGradeRef = {column: 'total_grade'}
    gradebook.setHeaderComponentRef('student', studentRef)
    gradebook.setHeaderComponentRef('total_grade', totalGradeRef)
    equal(gradebook.getHeaderComponentRef('student'), studentRef)
    equal(gradebook.getHeaderComponentRef('total_grade'), totalGradeRef)
  })

  test('#setHeaderComponentRef replaces an existing reference', function () {
    const ref = {column: 'student'}
    gradebook.setHeaderComponentRef('student', {column: 'previous'})
    gradebook.setHeaderComponentRef('student', ref)
    equal(gradebook.getHeaderComponentRef('student'), ref)
  })

  test('#removeHeaderComponentRef removes an existing reference', function () {
    const ref = {column: 'student'}
    gradebook.setHeaderComponentRef('student', ref)
    gradebook.removeHeaderComponentRef('student')
    equal(typeof gradebook.getHeaderComponentRef('student'), 'undefined')
  })

  test('sets grading period set to null when not defined in the env', () => {
    const gradingPeriodSet = createGradebook().gradingPeriodSet
    deepEqual(gradingPeriodSet, null)
  })

  test('when sections are loaded and there is no secondary info configured, set it to "section"', () => {
    const sections = [
      {id: 1, name: 'Section 1'},
      {id: 2, name: 'Section 2'},
    ]
    const gradebook = createGradebook({sections})

    strictEqual(gradebook.getSelectedSecondaryInfo(), 'section')
  })

  test('when one section is loaded and there is no secondary info configured, set it to "none"', () => {
    const sections = [{id: 1, name: 'Section 1'}]
    const gradebook = createGradebook({sections})

    strictEqual(gradebook.getSelectedSecondaryInfo(), 'none')
  })

  test('when zero sections are loaded and there is no secondary info configured, set it to "none"', () => {
    const sections = []
    const gradebook = createGradebook({sections})

    strictEqual(gradebook.getSelectedSecondaryInfo(), 'none')
  })
})
