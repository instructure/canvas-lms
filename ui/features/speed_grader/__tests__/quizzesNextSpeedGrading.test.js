/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import QuizzesNextSpeedGrading from '../QuizzesNextSpeedGrading'

describe('QuizzesNextSpeedGrading', () => {
  let fakeIframeHolder
  let fakeEG
  let speedGraderWindow
  let postMessageMock
  let registerCallback
  let refreshGradesCallback
  let addEventListenerMock

  beforeEach(() => {
    postMessageMock = jest.fn()
    fakeIframeHolder = {
      children: jest.fn().mockReturnValue([
        {
          contentWindow: {
            postMessage: postMessageMock,
          },
        },
      ]),
    }

    registerCallback = jest.fn()
    refreshGradesCallback = jest.fn()
    addEventListenerMock = jest.fn()

    fakeEG = {
      next: jest.fn(),
      prev: jest.fn(),
      refreshSubmissionsToView: jest.fn(),
      showGrade: jest.fn(),
      showDiscussion: jest.fn(),
      showRubric: jest.fn(),
      updateStatsInHeader: jest.fn(),
      refreshFullRubric: jest.fn(),
      setGradeReadOnly: jest.fn(),
      showSubmissionDetails: jest.fn(),
    }

    speedGraderWindow = {
      addEventListener: addEventListenerMock,
    }
  })

  describe('setup', () => {
    it('adds a message event listener to window', () => {
      QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      expect(addEventListenerMock).toHaveBeenCalledWith('message', expect.any(Function))
    })

    it('sets grade to read only with a quizzesNext.register message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      fns.onMessage({data: {subject: 'quizzesNext.register'}})
      expect(fakeEG.setGradeReadOnly).toHaveBeenCalledWith(true)
    })

    it('calls the registerCallback with a quizzesNext.register message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      fns.onMessage({data: {subject: 'quizzesNext.register'}})
      expect(registerCallback).toHaveBeenCalledWith(fns.postChangeSubmissionMessage, {
        singleLtiLaunch: true,
      })
    })

    it('calls the refreshGradesCallback with a quizzesNext.submissionUpdate message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      fns.onMessage({data: {subject: 'quizzesNext.submissionUpdate'}})
      expect(refreshGradesCallback).toHaveBeenCalledWith(
        fns.quizzesNextChange,
        expect.any(Function),
        1000,
      )
    })

    it('calls EG.prev with a quizzesNext.previousStudent message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      fns.onMessage({data: {subject: 'quizzesNext.previousStudent'}})
      expect(fakeEG.prev).toHaveBeenCalled()
    })

    it('calls EG.next with a quizzesNext.nextStudent message', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      fns.onMessage({data: {subject: 'quizzesNext.nextStudent'}})
      expect(fakeEG.next).toHaveBeenCalled()
    })

    it('calls the correct functions on EG when quizzesNextChange is called', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      const fakeSubmissionData = {}
      fns.quizzesNextChange(fakeSubmissionData)

      expect(fakeEG.refreshSubmissionsToView).toHaveBeenCalled()
      expect(fakeEG.showGrade).toHaveBeenCalled()
      expect(fakeEG.showDiscussion).toHaveBeenCalled()
      expect(fakeEG.showRubric).toHaveBeenCalled()
      expect(fakeEG.updateStatsInHeader).toHaveBeenCalled()
      expect(fakeEG.refreshFullRubric).toHaveBeenCalled()
      expect(fakeEG.setGradeReadOnly).toHaveBeenCalled()
    })

    it('postChangeSubmissionMessage calls postMessage with the submission data', () => {
      const fns = QuizzesNextSpeedGrading.setup(
        fakeEG,
        fakeIframeHolder,
        registerCallback,
        refreshGradesCallback,
        speedGraderWindow,
      )
      const arbitrarySubmissionData = {}
      fns.postChangeSubmissionMessage(arbitrarySubmissionData)
      expect(fakeEG.showSubmissionDetails).toHaveBeenCalled()
      expect(postMessageMock).toHaveBeenCalledWith(
        {
          subject: 'canvas.speedGraderSubmissionChange',
          submission: arbitrarySubmissionData,
        },
        '*',
      )
    })
  })
})
