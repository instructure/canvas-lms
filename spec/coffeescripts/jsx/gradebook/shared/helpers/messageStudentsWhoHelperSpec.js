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

import _ from 'lodash'
import MessageStudentsWhoHelper from '@canvas/grading/messageStudentsWhoHelper'

QUnit.module('messageStudentsWhoHelper#options', function (hooks) {
  hooks.beforeEach(function () {
    this.assignment = {id: '1', name: 'Shootbags'}
  })
  test("Includes the 'Haven't been graded' option if there are submissions", function () {
    sinon.stub(MessageStudentsWhoHelper, 'hasSubmission').returns(true)
    const options = MessageStudentsWhoHelper.options(this.assignment)
    deepEqual(options[1].text, "Haven't been graded")
    MessageStudentsWhoHelper.hasSubmission.restore()
  })
  test("Does not include the 'Haven't been graded' option if there are no submissions", function () {
    sinon.stub(MessageStudentsWhoHelper, 'hasSubmission').returns(false)
    const options = MessageStudentsWhoHelper.options(this.assignment)
    deepEqual(options[1].text, 'Scored less than')
    MessageStudentsWhoHelper.hasSubmission.restore()
  })

  QUnit.module("'Haven't been graded' criteria function", function (hooks) {
    hooks.beforeEach(function () {
      const assignment = {id: '1', name: 'Homework', submissionTypes: ['online_text_entry']}
      const options = MessageStudentsWhoHelper.options(assignment)
      const option = options.find(option => option.text === "Haven't been graded")
      this.hasNotBeenGraded = option.criteriaFn
    })
    test('returns false if the submission is excused', function () {
      const submission = {excused: true, score: null}
      strictEqual(this.hasNotBeenGraded(submission), false)
    })
    test('returns true if score is null and submission is not excused', function () {
      const submission = {excused: false, score: null}
      strictEqual(this.hasNotBeenGraded(submission), true)
    })
    test('returns false if score is not null and submission is not excused', function () {
      const submission = {excused: false, score: 90}
      strictEqual(this.hasNotBeenGraded(submission), false)
    })
  })

  QUnit.module("'Haven't Submitted Yet' criteria function", function (hooks) {
    hooks.beforeEach(function () {
      const assignment = {id: '1', name: 'Homework', submissionTypes: ['online_text_entry']}
      const options = MessageStudentsWhoHelper.options(assignment)
      const option = options.find(option => option.text === "Haven't submitted yet")
      this.hasNotSubmitted = option.criteriaFn
    })

    test('returns true if the submission has not been submitted', function () {
      const submission = {excused: false, latePolicyStatus: null, submittedAt: null}
      strictEqual(this.hasNotSubmitted(submission), true)
    })

    test('returns true if the submission has not been submitted (with snake-cased key)', function () {
      const submission = {excused: false, latePolicyStatus: null, submitted_at: null}
      strictEqual(this.hasNotSubmitted(submission), true)
    })

    test('returns false if the submission has been submitted', function () {
      const submission = {excused: false, latePolicyStatus: null, submittedAt: new Date()}
      strictEqual(this.hasNotSubmitted(submission), false)
    })

    test('returns false if the submission has been submitted (with snake-cased key)', function () {
      const submission = {excused: false, latePolicyStatus: null, submitted_at: new Date()}
      strictEqual(this.hasNotSubmitted(submission), false)
    })

    test("returns true if the submission status has been set to 'Missing'", function () {
      const submission = {excused: false, latePolicyStatus: 'missing', submittedAt: null}
      strictEqual(this.hasNotSubmitted(submission), true)
    })

    test("returns false if the submission status has been set to anything other than 'Missing'", function () {
      const submission = {excused: false, latePolicyStatus: 'late', submittedAt: null}
      strictEqual(this.hasNotSubmitted(submission), false)
    })

    test("returns true if the submission status has been set to 'Missing' and the student has submitted", function () {
      const submission = {excused: false, latePolicyStatus: 'missing', submittedAt: new Date()}
      strictEqual(this.hasNotSubmitted(submission), true)
    })

    test('returns false if the submission is excused', function () {
      const submission = {excused: true, latePolicyStatus: null, submittedAt: null}
      strictEqual(this.hasNotSubmitted(submission), false)
    })

    test('returns false if the submission is excused and the student has not submitted', function () {
      const submission = {excused: true, latePolicyStatus: null, submittedAt: null}
      strictEqual(this.hasNotSubmitted(submission), false)
    })
  })
})

QUnit.module('messageStudentsWhoHelper#hasSubmission')

test('returns false if there are no submission types', () => {
  const assignment = {id: '1', name: 'Shootbags', submission_types: []}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test('returns false if there are no submission types and submissionTypes is camelCase', () => {
  const assignment = {id: '1', name: 'Shootbags', submissionTypes: []}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission type is 'none'", () => {
  const assignment = {id: '1', name: 'Shootbags', submission_types: ['none']}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission type is 'none' and submissionTypes is camelCase", () => {
  const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['none']}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission type is 'on_paper'", () => {
  const assignment = {id: '1', name: 'Shootbags', submission_types: ['on_paper']}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission type is 'on_paper' and submissionTypes is camelCase", () => {
  const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['on_paper']}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission types are 'none' and 'on_paper'", () => {
  const assignment = {id: '1', name: 'Shootbags', submission_types: ['none', 'on_paper']}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns false if the only submission types are 'none' and 'on_paper' and submissionTypes is camelCase", () => {
  const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['none', 'on_paper']}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, false)
})

test("returns true if there is at least one submission that is not of type 'non' or 'on_paper'", () => {
  const assignment = {id: '1', name: 'Shootbags', submission_types: ['online_quiz']}
  const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
  deepEqual(hasSubmission, true)
})

test("returns true if there is at least one submission that is not of type 'non' or 'on_paper' and submissionTypes is camelCase", () => {
  const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['online_quiz']}
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
  let cutoff
  let scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, false)
  cutoff = null
  scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
  deepEqual(scoreWithCutoff, false)
})

QUnit.module('messageStudentsWhoHelper#callbackFn')

test('returns the student ids filtered by the correct criteria', () => {
  const option = {
    criteriaFn: (student, cutoff) => student.score > cutoff,
  }
  sandbox.stub(MessageStudentsWhoHelper, 'findOptionByText').returns(option)
  const students = [{user_data: {id: '1', score: 8}}, {user_data: {id: '2', score: 4}}]
  const cutoff = 5
  const selected = 'Scored more than'
  const filteredStudents = MessageStudentsWhoHelper.callbackFn(selected, cutoff, students)
  deepEqual(filteredStudents.length, 1)
  deepEqual(filteredStudents[0], '1')
})

QUnit.module('messageStudentsWhoHelper#generateSubjectCallbackFn')

test('generates a function that returns the subject string', () => {
  const option = {
    subjectFn: (assignment, cutoff) => `name: ${assignment.name}, cutoff: ${cutoff}`,
  }
  sandbox.stub(MessageStudentsWhoHelper, 'findOptionByText').returns(option)
  const assignment = {id: '1', name: 'Shootbags'}
  const cutoff = 5
  const subjectCallbackFn = MessageStudentsWhoHelper.generateSubjectCallbackFn(assignment)
  deepEqual(subjectCallbackFn(assignment, cutoff), 'name: Shootbags, cutoff: 5')
})

QUnit.module('messageStudentsWhoHelper#settings')

test('returns an object with the expected settings', () => {
  const assignment = {id: '1', name: 'Shootbags', points_possible: 5, course_id: '5'}
  const students = [{id: '1', name: 'Dora'}]
  const self = {
    options: () => 'stuff',
    callbackFn: () => 'call me back!',
    generateSubjectCallbackFn: () => () => 'function inception',
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
    'subjectCallback',
  ]
  deepEqual(settingsKeys, expectedKeys)
})

test('returns an object with the expected settings and courseId is camelCase', () => {
  const assignment = {id: '1', name: 'Shootbags', points_possible: 5, courseId: '5'}
  const students = [{id: '1', name: 'Dora'}]
  const self = {
    options: () => 'stuff',
    callbackFn: () => 'call me back!',
    generateSubjectCallbackFn: () => () => 'function inception',
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
    'subjectCallback',
  ]
  deepEqual(settingsKeys, expectedKeys)
})

QUnit.module('messageStudentsWhoHelper#messageStudentsWho', hooks => {
  const recipientsIds = [1, 2, 3, 4]
  const subject = 'foo'
  const body = 'bar'
  const contextCode = '1'
  const sendMessageStudentsWhoUrl = `/api/v1/conversations`
  const data = {}
  let server

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
    const responseBody = JSON.stringify(data)
    server.respondWith('POST', sendMessageStudentsWhoUrl, [
      200,
      {'Content-Type': 'application/json'},
      responseBody,
    ])
  })

  hooks.afterEach(() => {
    server.restore()
  })

  function getRequest() {
    // filter requests to eliminate spec pollution from unrelated specs
    return _.find(server.requests, request => request.url.includes(sendMessageStudentsWhoUrl))
  }

  test('sends a post request to the "conversations" url', () =>
    MessageStudentsWhoHelper.sendMessageStudentsWho(recipientsIds, subject, body, contextCode).then(
      () => {
        const request = getRequest()
        strictEqual(request.method, 'POST')
        strictEqual(request.url, sendMessageStudentsWhoUrl)
      }
    ))

  test('sends async for mode parameter', () =>
    MessageStudentsWhoHelper.sendMessageStudentsWho(recipientsIds, subject, body, contextCode)
      .then(() => {})
      .then(() => {
        const bodyData = JSON.parse(getRequest().requestBody)
        deepEqual(bodyData.mode, 'async')
      }))

  test('sends true for group_conversation parameter', () =>
    MessageStudentsWhoHelper.sendMessageStudentsWho(recipientsIds, subject, body, contextCode).then(
      () => {
        const bodyData = JSON.parse(getRequest().requestBody)
        deepEqual(bodyData.group_conversation, true)
      }
    ))

  test('sends true for bulk_message parameter', () =>
    MessageStudentsWhoHelper.sendMessageStudentsWho(recipientsIds, subject, body, contextCode).then(
      () => {
        const bodyData = JSON.parse(getRequest().requestBody)
        deepEqual(bodyData.bulk_message, true)
      }
    ))

  test('includes media comment params if passed a media file', () =>
    MessageStudentsWhoHelper.sendMessageStudentsWho(recipientsIds, subject, body, contextCode, {
      id: '123',
      type: 'video',
    }).then(() => {
      const bodyData = JSON.parse(getRequest().requestBody)
      strictEqual(bodyData.media_comment_id, '123')
      strictEqual(bodyData.media_comment_type, 'video')
    }))

  test('includes attachment_ids param if passed attachment ids', () =>
    MessageStudentsWhoHelper.sendMessageStudentsWho(
      recipientsIds,
      subject,
      body,
      contextCode,
      null,
      ['4', '8']
    ).then(() => {
      const bodyData = JSON.parse(getRequest().requestBody)
      deepEqual(bodyData.attachment_ids, ['4', '8'])
    }))

  test('does not include media comment params if not passed a media file', () =>
    MessageStudentsWhoHelper.sendMessageStudentsWho(recipientsIds, subject, body, contextCode).then(
      () => {
        const bodyData = JSON.parse(getRequest().requestBody)
        notOk(Object.keys(bodyData).includes('media_comment_id'))
        notOk(Object.keys(bodyData).includes('media_comment_type'))
      }
    ))
})
