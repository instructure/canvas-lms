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
import MessageStudentsWhoHelper from '../messageStudentsWhoHelper'
import axios from '@canvas/axios'

jest.mock('@canvas/axios')

describe('MessageStudentsWhoHelper', () => {
  let assignment

  beforeEach(() => {
    assignment = {id: '1', name: 'Shootbags'}
  })

  describe('#options', () => {
    test("Includes the 'Haven't been graded' option if there are submissions", () => {
      jest.spyOn(MessageStudentsWhoHelper, 'hasSubmission').mockReturnValue(true)
      const options = MessageStudentsWhoHelper.options(assignment)
      expect(options[1].text).toBe("Haven't been graded")
      MessageStudentsWhoHelper.hasSubmission.mockRestore()
    })

    test("Does not include the 'Haven't been graded' option if there are no submissions", () => {
      jest.spyOn(MessageStudentsWhoHelper, 'hasSubmission').mockReturnValue(false)
      const options = MessageStudentsWhoHelper.options(assignment)
      expect(options[1].text).toBe('Scored less than')
      MessageStudentsWhoHelper.hasSubmission.mockRestore()
    })

    describe("'Haven't been graded' criteria function", () => {
      let hasNotBeenGraded

      beforeEach(() => {
        const assignment = {id: '1', name: 'Homework', submissionTypes: ['online_text_entry']}
        const options = MessageStudentsWhoHelper.options(assignment)
        const option = options.find(option => option.text === "Haven't been graded")
        hasNotBeenGraded = option.criteriaFn
      })

      test('returns false if the submission is excused', () => {
        const submission = {excused: true, score: null}
        expect(hasNotBeenGraded(submission)).toBe(false)
      })

      test('returns true if score is null and submission is not excused', () => {
        const submission = {excused: false, score: null}
        expect(hasNotBeenGraded(submission)).toBe(true)
      })

      test('returns false if score is not null and submission is not excused', () => {
        const submission = {excused: false, score: 90}
        expect(hasNotBeenGraded(submission)).toBe(false)
      })
    })

    describe("'Haven't Submitted Yet' criteria function", () => {
      let hasNotSubmitted

      beforeEach(() => {
        const assignment = {id: '1', name: 'Homework', submissionTypes: ['online_text_entry']}
        const options = MessageStudentsWhoHelper.options(assignment)
        const option = options.find(option => option.text === "Haven't submitted yet")
        hasNotSubmitted = option.criteriaFn
      })

      test('returns true if the submission has not been submitted', () => {
        const submission = {excused: false, latePolicyStatus: null, submittedAt: null}
        expect(hasNotSubmitted(submission)).toBe(true)
      })

      test('returns true if the submission has not been submitted (with snake-cased key)', () => {
        const submission = {excused: false, latePolicyStatus: null, submitted_at: null}
        expect(hasNotSubmitted(submission)).toBe(true)
      })

      test('returns false if the submission has been submitted', () => {
        const submission = {excused: false, latePolicyStatus: null, submittedAt: new Date()}
        expect(hasNotSubmitted(submission)).toBe(false)
      })

      test('returns false if the submission has been submitted (with snake-cased key)', () => {
        const submission = {excused: false, latePolicyStatus: null, submitted_at: new Date()}
        expect(hasNotSubmitted(submission)).toBe(false)
      })

      test("returns true if the submission status has been set to 'Missing'", () => {
        const submission = {excused: false, latePolicyStatus: 'missing', submittedAt: null}
        expect(hasNotSubmitted(submission)).toBe(true)
      })

      test("returns false if the submission status has been set to anything other than 'Missing'", () => {
        const submission = {excused: false, latePolicyStatus: 'late', submittedAt: null}
        expect(hasNotSubmitted(submission)).toBe(false)
      })

      test("returns true if the submission status has been set to 'Missing' and the student has submitted", () => {
        const submission = {excused: false, latePolicyStatus: 'missing', submittedAt: new Date()}
        expect(hasNotSubmitted(submission)).toBe(true)
      })

      test('returns false if the submission is excused', () => {
        const submission = {excused: true, latePolicyStatus: null, submittedAt: null}
        expect(hasNotSubmitted(submission)).toBe(false)
      })

      test('returns false if the submission is excused and the student has not submitted', () => {
        const submission = {excused: true, latePolicyStatus: null, submittedAt: null}
        expect(hasNotSubmitted(submission)).toBe(false)
      })
    })
  })

  describe('#hasSubmission', () => {
    test('returns false if there are no submission types', () => {
      const assignment = {id: '1', name: 'Shootbags', submission_types: []}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test('returns false if there are no submission types and submissionTypes is camelCase', () => {
      const assignment = {id: '1', name: 'Shootbags', submissionTypes: []}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test("returns false if the only submission type is 'none'", () => {
      const assignment = {id: '1', name: 'Shootbags', submission_types: ['none']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test("returns false if the only submission type is 'none' and submissionTypes is camelCase", () => {
      const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['none']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test("returns false if the only submission type is 'on_paper'", () => {
      const assignment = {id: '1', name: 'Shootbags', submission_types: ['on_paper']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test("returns false if the only submission type is 'on_paper' and submissionTypes is camelCase", () => {
      const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['on_paper']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test("returns false if the only submission types are 'none' and 'on_paper'", () => {
      const assignment = {id: '1', name: 'Shootbags', submission_types: ['none', 'on_paper']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test("returns false if the only submission types are 'none' and 'on_paper' and submissionTypes is camelCase", () => {
      const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['none', 'on_paper']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(false)
    })

    test("returns true if there is at least one submission that is not of type 'non' or 'on_paper'", () => {
      const assignment = {id: '1', name: 'Shootbags', submission_types: ['online_quiz']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(true)
    })

    test("returns true if there is at least one submission that is not of type 'non' or 'on_paper' and submissionTypes is camelCase", () => {
      const assignment = {id: '1', name: 'Shootbags', submissionTypes: ['online_quiz']}
      const hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
      expect(hasSubmission).toBe(true)
    })
  })

  describe('#scoreWithCutoff', () => {
    test('returns true if the student has a non-empty-string score and a cutoff', () => {
      const student = {score: 6}
      const cutoff = 5
      const scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
      expect(scoreWithCutoff).toBe(true)
    })

    test('returns false if the student has an empty-string score', () => {
      const student = {score: ''}
      const cutoff = 5
      const scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
      expect(scoreWithCutoff).toBe(false)
    })

    test('returns false if the student score is null or undefined', () => {
      const student = {}
      const cutoff = 5
      let scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
      expect(scoreWithCutoff).toBe(false)
      student.score = null
      scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
      expect(scoreWithCutoff).toBe(false)
    })

    test('returns false if the cutoff is null or undefined', () => {
      const student = {score: 5}
      const cutoff = undefined
      let scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
      expect(scoreWithCutoff).toBe(false)
      const nullCutoff = null
      scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, nullCutoff)
      expect(scoreWithCutoff).toBe(false)
    })
  })

  describe('#callbackFn', () => {
    test('returns the student ids filtered by the correct criteria', () => {
      const option = {
        criteriaFn: (student, cutoff) => student.score > cutoff,
      }
      jest.spyOn(MessageStudentsWhoHelper, 'findOptionByText').mockReturnValue(option)
      const students = [{user_data: {id: '1', score: 8}}, {user_data: {id: '2', score: 4}}]
      const cutoff = 5
      const selected = 'Scored more than'
      const filteredStudents = MessageStudentsWhoHelper.callbackFn(selected, cutoff, students)
      expect(filteredStudents).toHaveLength(1)
      expect(filteredStudents[0]).toBe('1')
    })
  })

  describe('#generateSubjectCallbackFn', () => {
    test('generates a function that returns the subject string', () => {
      const option = {
        subjectFn: (assignment, cutoff) => `name: ${assignment.name}, cutoff: ${cutoff}`,
      }
      jest.spyOn(MessageStudentsWhoHelper, 'findOptionByText').mockReturnValue(option)
      const assignment = {id: '1', name: 'Shootbags'}
      const cutoff = 5
      const subjectCallbackFn = MessageStudentsWhoHelper.generateSubjectCallbackFn(assignment)
      expect(subjectCallbackFn(assignment, cutoff)).toBe('name: Shootbags, cutoff: 5')
    })
  })

  describe('#settings', () => {
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
      expect(settingsKeys).toEqual(expectedKeys)
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
      expect(settingsKeys).toEqual(expectedKeys)
    })
  })

  describe('#messageStudentsWho', () => {
    const recipientsIds = [1, 2, 3, 4]
    const subject = 'foo'
    const body = 'bar'
    const contextCode = '1'
    const sendMessageStudentsWhoUrl = `/api/v1/conversations`
    const data = {}
    const mockedAxios = axios

    beforeEach(() => {
      jest.clearAllMocks()
      mockedAxios.post.mockResolvedValue({data})
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    test('sends a post request to the "conversations" url', async () => {
      await MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        contextCode,
      )
      expect(mockedAxios.post).toHaveBeenCalledWith(sendMessageStudentsWhoUrl, expect.any(Object))
    })

    test('sends async for mode parameter', async () => {
      await MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        contextCode,
      )
      expect(mockedAxios.post).toHaveBeenCalledWith(
        sendMessageStudentsWhoUrl,
        expect.objectContaining({mode: 'async'}),
      )
    })

    test('sends true for group_conversation parameter', async () => {
      await MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        contextCode,
      )
      expect(mockedAxios.post).toHaveBeenCalledWith(
        sendMessageStudentsWhoUrl,
        expect.objectContaining({group_conversation: true}),
      )
    })

    test('sends true for bulk_message parameter', async () => {
      await MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        contextCode,
      )
      expect(mockedAxios.post).toHaveBeenCalledWith(
        sendMessageStudentsWhoUrl,
        expect.objectContaining({bulk_message: true}),
      )
    })

    test('includes media comment params if passed a media file', async () => {
      await MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        contextCode,
        {
          id: '123',
          type: 'video',
        },
      )
      expect(mockedAxios.post).toHaveBeenCalledWith(
        sendMessageStudentsWhoUrl,
        expect.objectContaining({
          media_comment_id: '123',
          media_comment_type: 'video',
        }),
      )
    })

    test('includes attachment_ids param if passed attachment ids', async () => {
      await MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        contextCode,
        null,
        ['4', '8'],
      )
      expect(mockedAxios.post).toHaveBeenCalledWith(
        sendMessageStudentsWhoUrl,
        expect.objectContaining({
          attachment_ids: ['4', '8'],
        }),
      )
    })

    test('does not include media comment params if not passed a media file', async () => {
      await MessageStudentsWhoHelper.sendMessageStudentsWho(
        recipientsIds,
        subject,
        body,
        contextCode,
      )
      expect(mockedAxios.post).toHaveBeenCalledWith(
        sendMessageStudentsWhoUrl,
        expect.objectContaining({
          recipients: recipientsIds,
          subject,
          body,
          context_code: contextCode,
          mode: 'async',
          group_conversation: true,
          bulk_message: true,
        }),
      )
      const callArg = mockedAxios.post.mock.calls[0][1]
      expect(callArg.media_comment_id).toBeUndefined()
      expect(callArg.media_comment_type).toBeUndefined()
    })
  })
})
