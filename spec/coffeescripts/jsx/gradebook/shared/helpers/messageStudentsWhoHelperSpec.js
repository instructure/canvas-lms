/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'underscore'
import MessageStudentsWhoHelper from 'jsx/gradebook/shared/helpers/messageStudentsWhoHelper'

QUnit.module('messageStudentsWhoHelper#options', {
  setup() {
    this.assignment = {
      id: '1',
      name: 'Shootbags'
    }
  }
})

test("Includes the 'Haven't been graded' option if there are submissions", function() {
  this.stub(MessageStudentsWhoHelper, 'hasSubmission').returns(true)
  const options = MessageStudentsWhoHelper.options(this.assignment)
  deepEqual(options[1].text, "Haven't been graded")
})

test("Does not include the 'Haven't been graded' option if there are no submissions", function() {
  this.stub(MessageStudentsWhoHelper, 'hasSubmission').returns(false)
  const options = MessageStudentsWhoHelper.options(this.assignment)
  deepEqual(options[1].text, 'Scored less than')
})

QUnit.module('messageStudentsWhoHelper#hasSubmission')

test('returns false if there are no submission types', () => {
  const assignment = {
    id: '1',
    name: 'Shootbags',
    submission_types: []
  }
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission type is 'none'", () => {
  const assignment = {
    id: '1',
    name: 'Shootbags',
    submission_types: ['none']
  }
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission type is 'on_paper'", () => {
  const assignment = {
    id: '1',
    name: 'Shootbags',
    submission_types: ['on_paper']
  }
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission types are 'none' and 'on_paper'", () => {
  const assignment = {
    id: '1',
    name: 'Shootbags',
    submission_types: ['none', 'on_paper']
  }
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns true if there is at least one submission that is not of type 'non' or 'on_paper'", () => {
  const assignment = {
    id: '1',
    name: 'Shootbags',
    submission_types: ['online_quiz']
  }
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, true)
})

QUnit.module('messageStudentsWhoHelper#scoreWithCutoff')

test('returns true if the student has a non-empty-string score and a cutoff', () => {
  const student = {score: 6}
  const cutoff = 5
  const scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, true)
})

test('returns false if the student has an empty-string score', () => {
  const student = {score: ''}
  const cutoff = 5
  const scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, false)
})

test('returns false if the student score is null or undefined', () => {
  const student = {}
  const cutoff = 5
  let scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, false)
  student.score = null
  scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, false)
})

test('returns false if the cutoff is null or undefined', () => {
  const student = {score: 5}
  let scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, false)
  var cutoff = null
  scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, false)
})

QUnit.module('messageStudentsWhoHelper#callbackFn')

test('returns the student ids filtered by the correct criteria', function() {
  const option = {
    criteriaFn(student, cutoff) {
      return student.score > cutoff
    }
  }
  this.stub(MessageStudentsWhoHelper, 'findOptionByText').returns(option)
  const students = [
    {
      user_data: {
        id: '1',
        score: 8
      }
    },
    {
      user_data: {
        id: '2',
        score: 4
      }
    }
  ]
  const cutoff = 5
  const selected = 'Scored more than'
  const filteredStudents = MessageStudentsWhoHelper.callbackFn(selected, cutoff, students)
  deepEqual(filteredStudents.length, 1)
  deepEqual(filteredStudents[0], '1')
})

QUnit.module('messageStudentsWhoHelper#generateSubjectCallbackFn')

test('generates a function that returns the subject string', function() {
  const option = {
    subjectFn(assignment, cutoff) {
      return `name: ${assignment.name}, cutoff: ${cutoff}`
    }
  }
  this.stub(MessageStudentsWhoHelper, 'findOptionByText').returns(option)
  const assignment = {
    id: '1',
    name: 'Shootbags'
  }
  const cutoff = 5
  const subjectCallbackFn = MessageStudentsWhoHelper.generateSubjectCallbackFn(assignment)
  deepEqual(subjectCallbackFn(assignment, cutoff), 'name: Shootbags, cutoff: 5')
})

QUnit.module('messageStudentsWhoHelper#settings')

test('returns an object with the expected settings', () => {
  const assignment = {
    id: '1',
    name: 'Shootbags',
    points_possible: 5,
    course_id: '5'
  }
  const students = [
    {
      id: '1',
      name: 'Dora'
    }
  ]
  const self = {
    options() {
      return 'stuff'
    },
    callbackFn() {
      return 'call me back!'
    },
    generateSubjectCallbackFn() {
      return () => 'function inception'
    }
  }
  const settingsFn = MessageStudentsWhoHelper.settings.bind(self)
  const settings = settingsFn(assignment, students)
  const settingsKeys = _.keys(settings)
  const expectedKeys = [
    'options',
    'title',
    'points_possible',
    'students',
    'context_code',
    'callback',
    'subjectCallback'
  ]
  deepEqual(settingsKeys, expectedKeys)
})
