/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import quizzesNextSpeedGrading from 'jsx/grading/quizzesNextSpeedGrading'

const postMessageStub = sinon.stub()
const fakeIframeHolder = {
  children: sinon.stub().returns([
    {
      contentWindow: {
        postMessage: postMessageStub
      }
    }
  ])
}

const registerCbStub = sinon.stub()
const refreshGradesCbStub = sinon.stub()
const addEventListenerStub = sinon.stub()
const speedGraderWindow = {
  addEventListener: addEventListenerStub
}

const refreshSubmissionsToViewStub = sinon.stub()
const showGradeStub = sinon.stub()
const showDiscussionStub = sinon.stub()
const showRubricStub = sinon.stub()
const updateStatsInHeaderStub = sinon.stub()
const refreshFullRubricStub = sinon.stub()
const setGradeReadOnlStub = sinon.stub()
const showSubmissionDetailsStub = sinon.stub()

const fakeEG = {
  refreshSubmissionsToView: refreshSubmissionsToViewStub,
  showGrade: showGradeStub,
  showDiscussion: showDiscussionStub,
  showRubric: showRubricStub,
  updateStatsInHeader: updateStatsInHeaderStub,
  refreshFullRubric: refreshFullRubricStub,
  setGradeReadOnly: setGradeReadOnlStub,
  showSubmissionDetails: showSubmissionDetailsStub
}

const resetStubs = function() {
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
}

QUnit.module('quizzesNextSpeedGrading', {
  teardown() {
    resetStubs()
  }
})

test('adds a message event listener to window', function() {
  const fns = quizzesNextSpeedGrading(
    fakeEG,
    fakeIframeHolder,
    registerCbStub,
    refreshGradesCbStub,
    speedGraderWindow
  )
  ok(addEventListenerStub.calledWith('message'))
})

test('sets grade to read only with a quizzesNext.register message', function() {
  const fns = quizzesNextSpeedGrading(
    fakeEG,
    fakeIframeHolder,
    registerCbStub,
    refreshGradesCbStub,
    speedGraderWindow
  )
  fns.onMessage({data: {subject: 'quizzesNext.register'}})
  ok(fakeEG.setGradeReadOnly.calledWith(true))
})

test('calls the registerCallback with a quizzesNext.register message', function() {
  const fns = quizzesNextSpeedGrading(
    fakeEG,
    fakeIframeHolder,
    registerCbStub,
    refreshGradesCbStub,
    speedGraderWindow
  )
  fns.onMessage({data: {subject: 'quizzesNext.register'}})
  ok(registerCbStub.calledWith(fns.postChangeSubmissionMessage))
})

test('calls the refreshGradesCb with a quizzesNext.submissionUpdate message', function() {
  const fns = quizzesNextSpeedGrading(
    fakeEG,
    fakeIframeHolder,
    registerCbStub,
    refreshGradesCbStub,
    speedGraderWindow
  )
  fns.onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
  ok(refreshGradesCbStub.calledWith(fns.quizzesNextChange))
})

test('calls the correct functions on EG', function() {
  const fnsToCallOnEG = [
    'refreshSubmissionsToView',
    'showGrade',
    'showDiscussion',
    'showRubric',
    'updateStatsInHeader',
    'refreshFullRubric',
    'setGradeReadOnly'
  ]

  const fns = quizzesNextSpeedGrading(
    fakeEG,
    fakeIframeHolder,
    registerCbStub,
    refreshGradesCbStub,
    speedGraderWindow
  )
  const fakeSubmissionData = {}
  fns.quizzesNextChange(fakeSubmissionData)

  fnsToCallOnEG.forEach(function(egFunction) {
    ok(fakeEG[egFunction].called)
  })
})

test('postChangeSubmissionMessage postMessage with the submission data', function() {
  const fns = quizzesNextSpeedGrading(
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
      subject: 'canvas.speedGraderSubmissionChange'
    })
  )
})
