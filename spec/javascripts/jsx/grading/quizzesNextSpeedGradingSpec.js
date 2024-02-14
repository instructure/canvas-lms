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

import QuizzesNextSpeedGrading from 'ui/features/speed_grader/QuizzesNextSpeedGrading'

const postMessageStub = sinon.stub()
const fakeIframeHolder = {
  children: sinon.stub().returns([
    {
      contentWindow: {
        postMessage: postMessageStub,
      },
    },
  ]),
}

const registerCbStub = sinon.stub()
const refreshGradesCbStub = sinon.stub()
const addEventListenerStub = sinon.stub()

const nextStub = sinon.stub()
const prevStub = sinon.stub()
const refreshSubmissionsToViewStub = sinon.stub()
const showGradeStub = sinon.stub()
const showDiscussionStub = sinon.stub()
const showRubricStub = sinon.stub()
const updateStatsInHeaderStub = sinon.stub()
const refreshFullRubricStub = sinon.stub()
const setGradeReadOnlStub = sinon.stub()
const showSubmissionDetailsStub = sinon.stub()

const fakeEG = {
  next: nextStub,
  prev: prevStub,
  refreshSubmissionsToView: refreshSubmissionsToViewStub,
  showGrade: showGradeStub,
  showDiscussion: showDiscussionStub,
  showRubric: showRubricStub,
  updateStatsInHeader: updateStatsInHeaderStub,
  refreshFullRubric: refreshFullRubricStub,
  setGradeReadOnly: setGradeReadOnlStub,
  showSubmissionDetails: showSubmissionDetailsStub,
}

const resetStubs = function () {
  nextStub.reset()
  prevStub.reset()
  registerCbStub.reset()
  refreshGradesCbStub.reset()
  addEventListenerStub.reset()
  refreshSubmissionsToViewStub.reset()
  showGradeStub.reset()
  showDiscussionStub.reset()
  showRubricStub.reset()
  updateStatsInHeaderStub.reset()
  refreshFullRubricStub.reset()
  setGradeReadOnlStub.reset()
  showSubmissionDetailsStub.reset()
  postMessageStub.reset()
}

QUnit.module('QuizzesNextSpeedGrading', suiteHooks => {
  let speedGraderWindow

  suiteHooks.beforeEach(() => {
    speedGraderWindow = {
      addEventListener: addEventListenerStub,
    }
  })

  suiteHooks.afterEach(() => {
    resetStubs()
  })

  QUnit.module('setup', () => {
    test('adds a message event listener to window', () => {
      QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      ok(addEventListenerStub.calledWith('message'))
    })

    test('sets grade to read only with a quizzesNext.register message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      fns.onMessage({data: {subject: 'quizzesNext.register'}})
      ok(fakeEG.setGradeReadOnly.calledWith(true))
    })

    test('calls the registerCallback with a quizzesNext.register message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      fns.onMessage({data: {subject: 'quizzesNext.register'}})
      ok(registerCbStub.calledWith(fns.postChangeSubmissionMessage))
    })

    test('calls the refreshGradesCb with a quizzesNext.submissionUpdate message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      fns.onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
      ok(refreshGradesCbStub.calledWith(fns.quizzesNextChange))
    })

    test('calls EG.prev with a quizzesNext.previousStudent message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      fns.onMessage({data: {subject: 'quizzesNext.previousStudent'}})
      ok(fakeEG.prev.calledOnce)
    })

    test('calls EG.next with a quizzesNext.nextStudent message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      fns.onMessage({data: {subject: 'quizzesNext.nextStudent'}})
      ok(fakeEG.next.calledOnce)
    })

    test('calls the correct functions on EG', () => {
      const fnsToCallOnEG = [
        'refreshSubmissionsToView',
        'showGrade',
        'showDiscussion',
        'showRubric',
        'updateStatsInHeader',
        'refreshFullRubric',
        'setGradeReadOnly',
      ]

      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      const fakeSubmissionData = {}
      fns.quizzesNextChange(fakeSubmissionData)

      fnsToCallOnEG.forEach(egFunction => {
        ok(fakeEG[egFunction].called)
      })
    })

    test('postChangeSubmissionMessage postMessage with the submission data', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCbStub,
        refreshGradesCbStub,
        speedGraderWindow
      )
      const arbitrarySubmissionData = {}
      fns.postChangeSubmissionMessage(arbitrarySubmissionData)
      ok(showSubmissionDetailsStub.called)
      ok(
        postMessageStub.calledWith({
          submission: arbitrarySubmissionData,
          subject: 'canvas.speedGraderSubmissionChange',
        })
      )
    })

    QUnit.module('polling for refreshed grades', contextHooks => {
      let originalSubmission
      let submission
      let numRequests
      let onMessage

      contextHooks.beforeEach(() => {
        submission = {graded_at: '2016-07-11T19:22:14Z'}
        originalSubmission = {graded_at: '2016-07-11T19:22:14Z'}
        numRequests = 1
        refreshGradesCbStub.callsArgWith(1, submission, originalSubmission, numRequests)
        onMessage = QuizzesNextSpeedGrading.setup(
          fakeEG,
          fakeIframeHolder,
          registerCbStub,
          refreshGradesCbStub,
          speedGraderWindow
        ).onMessage
      })

      test('re-polls for updated grades if submission graded_at has not been updated', () => {
        const refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        ok(refreshGrades)
      })

      test('re-polls for updated grades if submission graded_at was originally blank and is still blank', () => {
        originalSubmission.graded_at = null
        submission.graded_at = null
        const refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        ok(refreshGrades)
      })

      test('re-polls for updated grades if submission graded_at was originally present and is now blank', () => {
        originalSubmission.graded_at = '2016-07-11T19:22:14Z'
        submission.graded_at = null
        const refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        ok(refreshGrades)
      })

      test('does not re-poll for updated grades if submission graded_at was originally blank and is now set', () => {
        originalSubmission.graded_at = null
        submission.graded_at = '2016-07-11T19:22:14Z'
        const refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        notOk(refreshGrades)
      })

      test('does not re-poll for updated grades if submission graded_at has been updated', () => {
        originalSubmission.graded_at = '2016-07-11T19:22:14Z'
        submission.graded_at = '2016-07-12T19:22:14Z'
        const refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        notOk(refreshGrades)
      })

      test('does not re-poll if max requests have been made (even if graded_at has not been updated)', () => {
        originalSubmission.graded_at = '2016-07-11T19:22:14Z'
        submission.graded_at = '2016-07-11T19:22:14Z'
        refreshGradesCbStub.callsArgWith(1, submission, originalSubmission, 20)
        const refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        notOk(refreshGrades)
      })

      test('defaults to 20 max requests', () => {
        originalSubmission.graded_at = '2016-07-11T19:22:14Z'
        submission.graded_at = '2016-07-11T19:22:14Z'
        refreshGradesCbStub.callsArgWith(1, submission, originalSubmission, 19)
        let refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        ok(refreshGrades)
        refreshGradesCbStub.callsArgWith(1, submission, originalSubmission, 20)
        refreshGrades = onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
        notOk(refreshGrades)
      })
    })
  })

  QUnit.module('postGradeByQuestionChangeMessage', () => {
    test('posts a message with the enabled state of the grade by question feature', () => {
      QuizzesNextSpeedGrading.postGradeByQuestionChangeMessage(fakeIframeHolder, true)
      ok(
        postMessageStub.calledOnceWith({
          subject: 'canvas.speedGraderGradeByQuestionChange',
          enabled: true,
        })
      )

      postMessageStub.resetHistory()
      QuizzesNextSpeedGrading.postGradeByQuestionChangeMessage(fakeIframeHolder, false)
      ok(
        postMessageStub.calledOnceWith({
          subject: 'canvas.speedGraderGradeByQuestionChange',
          enabled: false,
        })
      )
    })
  })

  QUnit.module('postChangeSubmissionVersionMessage', () => {
    test('posts a message with the external_tool_url set to show quiz attempt', () => {
      const submission = {
        url: 'http://quiz-lti.docker/lti/launch?participant_session_id=1&quiz_session_id=1',
      }
      QuizzesNextSpeedGrading.postChangeSubmissionVersionMessage(fakeIframeHolder, submission)
      ok(
        postMessageStub.calledOnceWith({
          subject: 'canvas.speedGraderSubmissionChange',
          submission: {
            ...submission,
            external_tool_url:
              'http://quiz-lti.docker/lti/launch?participant_session_id=1&quiz_session_id=1',
          },
        })
      )
    })
  })
})
