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

import moxios from 'moxios'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import SubmissionCommentApi from 'ui/features/gradebook/react/default_gradebook/apis/SubmissionCommentApi'

QUnit.module('#updateSubmissionComments', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('calls renderSubmissionTray', function () {
  const renderSubmissionTrayStub = sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionComments([])
  strictEqual(renderSubmissionTrayStub.callCount, 1)
})

test('sets the edited comment ID to null', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.setEditedCommentId('5')
  this.gradebook.updateSubmissionComments([])
  strictEqual(this.gradebook.getSubmissionTrayState().editedCommentId, null)
})

test('calls setSubmissionComments (2)', function () {
  const setSubmissionCommentsStub = sandbox.stub(this.gradebook, 'setSubmissionComments')
  this.gradebook.unloadSubmissionComments()
  strictEqual(setSubmissionCommentsStub.callCount, 1)
})

test('calls setSubmissionComments with an empty collection of comments', function () {
  const setSubmissionCommentsStub = sandbox.stub(this.gradebook, 'setSubmissionComments')
  this.gradebook.unloadSubmissionComments()
  deepEqual(setSubmissionCommentsStub.firstCall.args[0], [])
})

test('calls setSubmissionCommentsLoaded', function () {
  const setSubmissionCommentsLoadedStub = sandbox.stub(
    this.gradebook,
    'setSubmissionCommentsLoaded'
  )
  this.gradebook.unloadSubmissionComments()
  strictEqual(setSubmissionCommentsLoadedStub.callCount, 1)
})

test('calls setSubmissionCommentsLoaded with an empty collection of comments', function () {
  const setSubmissionCommentsLoadedStub = sandbox.stub(
    this.gradebook,
    'setSubmissionCommentsLoaded'
  )
  this.gradebook.unloadSubmissionComments()
  strictEqual(setSubmissionCommentsLoadedStub.firstCall.args[0], false)
})

QUnit.module('#apiCreateSubmissionComment', hooks => {
  let assignment
  let createSubmissionCommentStub
  let gradebook
  let student
  let sandbox

  hooks.beforeEach(() => {
    sandbox = sinon.createSandbox()
    assignment = {grade_group_students_individually: true, group_category_id: '2201', id: '2301'}
    createSubmissionCommentStub = sandbox.stub(SubmissionCommentApi, 'createSubmissionComment')
    createSubmissionCommentStub.resolves()
    gradebook = createGradebook()
    student = {
      enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
      id: '1101',
      name: 'Adam Jones',
    }
    gradebook.setAssignments({2301: assignment})
    gradebook.gotChunkOfStudents([student])
  })

  hooks.afterEach(() => {
    sandbox.restore()
  })

  test('calls the success function on a successful call', () => {
    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    const updateSubmissionCommentsStub = sandbox.stub(gradebook, 'updateSubmissionComments')
    const promise = gradebook.apiCreateSubmissionComment('a comment')
    return promise.then(() => {
      strictEqual(updateSubmissionCommentsStub.callCount, 1)
    })
  })

  test('calls showFlashSuccess on a successful call', () => {
    sandbox.stub(gradebook, 'renderSubmissionTray')

    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    const showFlashSuccessStub = sandbox.stub(FlashAlert, 'showFlashSuccess')
    const promise = gradebook.apiCreateSubmissionComment('a comment')
    return promise.then(() => {
      strictEqual(showFlashSuccessStub.callCount, 1)
    })
  })

  test('calls the success function on an unsuccessful call', () => {
    createSubmissionCommentStub.rejects()

    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    const setCommentsUpdatingStub = sandbox.stub(gradebook, 'setCommentsUpdating')
    const promise = gradebook.apiCreateSubmissionComment('a comment')
    return promise.then(() => {
      strictEqual(setCommentsUpdatingStub.callCount, 1)
    })
  })

  test('calls showFlashError on an unsuccessful call', () => {
    createSubmissionCommentStub.rejects()

    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    const showFlashErrorStub = sandbox.stub(FlashAlert, 'showFlashError')
    const promise = gradebook.apiCreateSubmissionComment('a comment')
    return promise.then(() => {
      strictEqual(showFlashErrorStub.callCount, 1)
    })
  })

  test('includes comment group_comment in call', () => {
    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    gradebook.apiCreateSubmissionComment('a comment')
    const commentData = createSubmissionCommentStub.firstCall.args[3]
    strictEqual(commentData.group_comment, 0)
  })

  test('includes comment attempt in call if submission has attempt', () => {
    sandbox.stub(gradebook, 'getSubmission').returns({attempt: 3})
    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    gradebook.apiCreateSubmissionComment('a comment')
    const commentData = createSubmissionCommentStub.firstCall.args[3]
    strictEqual(commentData.attempt, 3)
  })

  test('does not include comment attempt in call if submission does not have attempt', () => {
    sandbox.stub(gradebook, 'getSubmission').returns({})
    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    gradebook.apiCreateSubmissionComment('a comment')
    const commentData = createSubmissionCommentStub.firstCall.args[3]
    notOk(Object.keys(commentData).includes('attempt'))
  })

  test('includes comment text_comment in call', () => {
    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    gradebook.apiCreateSubmissionComment('a comment')
    const commentData = createSubmissionCommentStub.firstCall.args[3]
    strictEqual(commentData.text_comment, 'a comment')
  })

  test('includes assignment id in call', () => {
    gradebook.setSubmissionTrayState(false, student.id, assignment.id)
    gradebook.apiCreateSubmissionComment('a comment')
    const assignmentId = createSubmissionCommentStub.firstCall.args[1]
    strictEqual(assignmentId, '2301')
  })

  QUnit.module('when assignment is a group assignment', contextHooks => {
    contextHooks.beforeEach(() => {
      assignment.grade_group_students_individually = false
      assignment.group_category_id = '2201'
    })

    test('group_comment in call is 0 when grading individually', () => {
      assignment.grade_group_students_individually = true
      gradebook.setSubmissionTrayState(false, student.id, assignment.id)
      gradebook.apiCreateSubmissionComment('a comment')
      const commentData = createSubmissionCommentStub.firstCall.args[3]
      strictEqual(commentData.group_comment, 0)
    })

    test('group_comment in call is 1 when not grading individually', () => {
      gradebook.setSubmissionTrayState(false, student.id, assignment.id)
      gradebook.apiCreateSubmissionComment('a comment')
      const commentData = createSubmissionCommentStub.firstCall.args[3]
      strictEqual(commentData.group_comment, 1)
    })
  })
})

QUnit.module('#apiUpdateSubmissionComment', hooks => {
  let gradebook
  const sandbox = sinon.createSandbox()
  const editedTimestamp = '2015-10-08T22:09:27Z'

  hooks.beforeEach(() => {
    moxios.install()
    gradebook = createGradebook()
    gradebook.setSubmissionComments([
      {id: '23', createdAt: '2015-10-04T22:09:27Z', editedAt: null, comment: 'a comment'},
      {id: '25', createdAt: '2015-10-05T22:09:27Z', editedAt: null, comment: 'another comment'},
    ])
  })

  hooks.afterEach(() => {
    FlashAlert.destroyContainer()
    moxios.uninstall()
    sandbox.restore()
  })

  function stubCommentUpdateSuccess(comment) {
    moxios.stubRequest('/submission_comments/23', {
      status: 200,
      response: {
        submission_comment: {
          id: '23',
          created_at: '2015-10-04T22:09:27Z',
          comment,
          edited_at: editedTimestamp,
        },
      },
    })
  }

  function stubCommentUpdateFailure(status) {
    moxios.stubRequest('/submission_comments/23', {status, response: []})
  }

  test('updates the comment if the call is successful', () => {
    sandbox.stub(gradebook, 'renderSubmissionTray')
    const updatedComment = 'an updated comment'
    stubCommentUpdateSuccess(updatedComment)

    return gradebook.apiUpdateSubmissionComment(updatedComment, '23').then(() => {
      const comment = gradebook.getSubmissionComments()[0].comment
      strictEqual(comment, updatedComment)
    })
  })

  test('updates the edited_at if the call is successful', () => {
    sandbox.stub(gradebook, 'renderSubmissionTray')
    const updatedComment = 'an updated comment'
    stubCommentUpdateSuccess(updatedComment)

    return gradebook.apiUpdateSubmissionComment(updatedComment, '23').then(() => {
      const editedAt = gradebook.getSubmissionComments()[0].editedAt
      strictEqual(editedAt.getTime(), new Date(editedTimestamp).getTime())
    })
  })

  test('flashes a success message if the call is successful', () => {
    sandbox.stub(gradebook, 'renderSubmissionTray')
    sandbox.stub(FlashAlert, 'showFlashSuccess').returns(() => {})
    const updatedComment = 'an updated comment'
    stubCommentUpdateSuccess(updatedComment)

    return gradebook.apiUpdateSubmissionComment(updatedComment, '23').then(() => {
      strictEqual(FlashAlert.showFlashSuccess.callCount, 1)
    })
  })

  test('leaves other comments unchanged if the call is successful', () => {
    sandbox.stub(gradebook, 'renderSubmissionTray')
    const updatedComment = 'an updated comment'
    stubCommentUpdateSuccess(updatedComment)
    const originalComment = gradebook.getSubmissionComments()[1]

    return gradebook.apiUpdateSubmissionComment('an updated comment', '23').then(() => {
      const comment = gradebook.getSubmissionComments()[1]
      strictEqual(comment, originalComment)
    })
  })

  test('does not update the comment state if the call is unsuccessful', () => {
    sandbox.stub(gradebook, 'renderSubmissionTray')
    stubCommentUpdateFailure(401)
    const originalComment = gradebook.getSubmissionComments()[0].comment

    return gradebook.apiUpdateSubmissionComment('an updated comment', '23').then(() => {
      const comment = gradebook.getSubmissionComments()[0].comment
      strictEqual(comment, originalComment)
    })
  })

  test('flashes an error message if the call is unsuccessful', () => {
    sandbox.stub(gradebook, 'renderSubmissionTray')
    sandbox.stub(FlashAlert, 'showFlashError').returns(() => {})
    stubCommentUpdateFailure(401)

    return gradebook.apiUpdateSubmissionComment('an updated comment', '23').then(() => {
      strictEqual(FlashAlert.showFlashError.callCount, 1)
    })
  })
})

QUnit.module('#apiDeleteSubmissionComment', {
  setup() {
    moxios.install()
    this.gradebook = createGradebook()
  },
  teardown() {
    FlashAlert.destroyContainer()
    moxios.uninstall()
  },
})

test('calls the success function on a successful call', function () {
  const url = '/submission_comments/42'

  moxios.stubRequest(url, {status: 200, response: []})

  const removeSubmissionCommentStub = sandbox.stub(this.gradebook, 'removeSubmissionComment')
  const promise = this.gradebook.apiDeleteSubmissionComment('42')
  return promise.then(() => {
    strictEqual(removeSubmissionCommentStub.callCount, 1)
  })
})

test('calls showFlashSuccess on a successful call', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray')
  const url = '/submission_comments/42'
  moxios.stubRequest(url, {status: 200, response: []})

  const showFlashSuccessStub = sandbox.stub(FlashAlert, 'showFlashSuccess')
  const promise = this.gradebook.apiDeleteSubmissionComment('42')
  return promise.then(() => {
    strictEqual(showFlashSuccessStub.callCount, 1)
  })
})

test('calls the success function on an unsuccessful call', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray')
  const url = '/submission_comments/42'
  moxios.stubRequest(url, {status: 401, response: []})

  const showFlashErrorStub = sandbox.stub(FlashAlert, 'showFlashError').returns(() => {})
  const promise = this.gradebook.apiDeleteSubmissionComment('42')
  return promise.then(() => {
    strictEqual(showFlashErrorStub.callCount, 1)
  })
})

test('calls removeSubmissionComment on success', function () {
  const url = '/submission_comments/42'

  moxios.stubRequest(url, {status: 200, response: []})

  const successStub = sinon.stub()
  const removeSubmissionCommentStub = sandbox.stub(this.gradebook, 'removeSubmissionComment')
  const promise = this.gradebook.apiDeleteSubmissionComment('42', successStub, () => {})
  return promise.then(() => {
    strictEqual(removeSubmissionCommentStub.callCount, 1)
  })
})

QUnit.module('#removeSubmissionComment', {
  setup() {
    this.gradebook = createGradebook()
  },
  comments() {
    return [
      {
        id: '42',
        author: {
          display_name: 'foo',
          avatar_image_url: '//avatar_image_url/',
          html_url: '//html_url/',
        },
        created_at: new Date('2017-09-15'),
        comment: 'a comment',
      },
    ]
  },
})

test('removes matching comment id', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.setSubmissionComments(this.comments())
  this.gradebook.removeSubmissionComment('42')
  deepEqual(this.gradebook.getSubmissionComments(), [])
})

test('removes none if no matching comment id', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.setSubmissionComments([{id: '84'}])
  this.gradebook.removeSubmissionComment('42')
  deepEqual(this.gradebook.getSubmissionComments(), [{id: '84'}])
})

QUnit.module('#editSubmissionComment', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    sinon.stub(gradebook, 'renderSubmissionTray')
  })

  hooks.afterEach(() => {
    gradebook.renderSubmissionTray.restore()
  })

  test('stores the id of the comment being edited', () => {
    gradebook.editSubmissionComment('23')
    strictEqual(gradebook.gridDisplaySettings.submissionTray.editedCommentId, '23')
  })

  test('renders the submission tray', () => {
    gradebook.editSubmissionComment('23')
    ok(gradebook.renderSubmissionTray.calledOnce)
  })
})

QUnit.module('#setEditedCommentId', () => {
  test('sets the editedCommentId', () => {
    const gradebook = createGradebook()
    gradebook.setEditedCommentId('23')
    strictEqual(gradebook.gridDisplaySettings.submissionTray.editedCommentId, '23')
  })
})

QUnit.module('#getSubmissionComments', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('is empty', function () {
  deepEqual(this.gradebook.getSubmissionComments(), [])
})

test('gets comments', function () {
  const comments = ['a comment']
  this.gradebook.setSubmissionComments(comments)
  deepEqual(this.gradebook.getSubmissionComments(), comments)
})

QUnit.module('#setSubmissionComments', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('sets comments on gridDisplaySettings.submissionTray', function () {
  const comments = ['a comment']
  this.gradebook.setSubmissionComments(comments)
  deepEqual(this.gradebook.gridDisplaySettings.submissionTray.comments, comments)
})
