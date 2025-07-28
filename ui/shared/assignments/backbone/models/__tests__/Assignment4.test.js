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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import fakeENV from '@canvas/test-utils/fakeENV'
import Assignment from '../Assignment'

describe('Assignment', () => {
  describe('#toView', () => {
    beforeEach(() => {
      fakeENV.setup({current_user_roles: ['teacher'], SETTINGS: {}})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    describe('basic assignment properties', () => {
      it('returns the assignment name', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.name('Todd')
        expect(assignment.toView().name).toBe('Todd')
      })

      it('returns the assignment dueAt', () => {
        const date = Date.now()
        const assignment = new Assignment({name: 'foo'})
        assignment.dueAt(date)
        expect(assignment.toView().dueAt).toBe(date)
      })

      it('includes the assignment description', () => {
        const description = 'Yo yo fasho'
        const assignment = new Assignment({name: 'foo'})
        assignment.description(description)
        expect(assignment.toView().description).toBe(description)
      })

      it('includes dueDateRequired setting', () => {
        const dueDateRequired = false
        const assignment = new Assignment({name: 'foo'})
        assignment.dueDateRequired(dueDateRequired)
        expect(assignment.toView().dueDateRequired).toBe(dueDateRequired)
      })

      it('returns points possible', () => {
        const pointsPossible = 12
        const assignment = new Assignment({name: 'foo'})
        assignment.pointsPossible(pointsPossible)
        expect(assignment.toView().pointsPossible).toBe(pointsPossible)
      })

      it('returns grading type', () => {
        const gradingType = 'percent'
        const assignment = new Assignment({name: 'foo'})
        assignment.gradingType(gradingType)
        expect(assignment.toView().gradingType).toBe(gradingType)
      })

      it('includes notifyOfUpdate setting', () => {
        const notifyOfUpdate = false
        const assignment = new Assignment({name: 'foo'})
        assignment.notifyOfUpdate(notifyOfUpdate)
        expect(assignment.toView().notifyOfUpdate).toBe(notifyOfUpdate)
      })
    })

    describe('dates handling', () => {
      it('returns lockAt', () => {
        const lockAt = Date.now()
        const assignment = new Assignment({name: 'foo'})
        assignment.lockAt(lockAt)
        expect(assignment.toView().lockAt).toBe(lockAt)
      })

      it('includes unlockAt', () => {
        const unlockAt = Date.now()
        const assignment = new Assignment({name: 'foo'})
        assignment.unlockAt(unlockAt)
        expect(assignment.toView().unlockAt).toBe(unlockAt)
      })

      it('includes multipleDueDates', () => {
        const assignment = new Assignment({
          all_dates: [{title: 'Summer'}, {title: 'Winter'}],
        })
        expect(assignment.toView().multipleDueDates).toBe(true)
      })

      it('includes allDates', () => {
        const assignment = new Assignment({
          all_dates: [{title: 'Summer'}, {title: 'Winter'}],
        })
        expect(assignment.toView().allDates).toHaveLength(2)
      })

      it('includes singleSectionDueDate', () => {
        const dueAt = new Date('2013-11-27T11:01:00Z')
        const assignment = new Assignment({
          all_dates: [
            {
              due_at: null,
              title: 'Everyone',
            },
            {
              due_at: dueAt,
              title: 'Summer',
            },
          ],
        })
        jest.spyOn(assignment, 'multipleDueDates').mockReturnValue(false)
        expect(assignment.toView().singleSectionDueDate).toBe(dueAt.toISOString())
      })
    })

    describe('peer review settings', () => {
      it('includes peerReviews setting', () => {
        const peerReviews = false
        const assignment = new Assignment({name: 'foo'})
        assignment.peerReviews(peerReviews)
        expect(assignment.toView().peerReviews).toBe(peerReviews)
      })

      it('includes automaticPeerReviews setting', () => {
        const autoPeerReviews = false
        const assignment = new Assignment({name: 'foo'})
        assignment.automaticPeerReviews(autoPeerReviews)
        expect(assignment.toView().automaticPeerReviews).toBe(autoPeerReviews)
      })
    })

    describe('submission type flags', () => {
      it('indicates whether assignment accepts uploads', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', ['online_upload'])
        expect(assignment.toView().acceptsOnlineUpload).toBe(true)
      })

      it('indicates whether assignment accepts media recordings', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', ['media_recording'])
        expect(assignment.toView().acceptsMediaRecording).toBe(true)
      })

      it('includes submissionType', () => {
        const assignment = new Assignment({
          name: 'foo',
          id: '16',
        })
        assignment.set('submission_types', ['on_paper'])
        expect(assignment.toView().submissionType).toBe('on_paper')
      })

      it('indicates whether assignment accepts online text entries', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', ['online_text_entry'])
        expect(assignment.toView().acceptsOnlineTextEntries).toBe(true)
      })

      it('indicates whether assignment accepts online URLs', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', ['online_url'])
        expect(assignment.toView().acceptsOnlineURL).toBe(true)
      })

      it('includes allowedExtensions', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.allowedExtensions([])
        expect(assignment.toView().allowedExtensions).toEqual([])
      })
    })

    describe('URL handling', () => {
      it('includes htmlUrl', () => {
        const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
        expect(assignment.toView().htmlUrl).toBe('http://example.com/assignments/1')
      })

      it('uses edit url for htmlUrl when managing a quiz_lti assignment', () => {
        const assignment = new Assignment({
          html_url: 'http://example.com/assignments/1',
          is_quiz_lti_assignment: true,
        })
        ENV.PERMISSIONS = {manage: true}
        expect(assignment.toView().htmlUrl).toBe('http://example.com/assignments/1/edit?quiz_lti')
        ENV.PERMISSIONS = {}
        ENV.FLAGS = {}
      })

      it('uses htmlUrl when not managing a quiz_lti assignment', () => {
        const assignment = new Assignment({
          html_url: 'http://example.com/assignments/1',
          is_quiz_lti_assignment: true,
        })
        ENV.PERMISSIONS = {manage: false}
        expect(assignment.toView().htmlUrl).toBe('http://example.com/assignments/1')
        ENV.PERMISSIONS = {}
        ENV.FLAGS = {}
      })

      it('includes htmlEditUrl', () => {
        const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
        expect(assignment.toView().htmlEditUrl).toBe('http://example.com/assignments/1/edit')
      })

      it('includes htmlBuildUrl', () => {
        const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
        expect(assignment.toView().htmlBuildUrl).toBe('http://example.com/assignments/1')
      })
    })

    describe('special assignment types', () => {
      it('includes fields for isPage', () => {
        const assignment = new Assignment({submission_types: ['wiki_page']})
        const json = assignment.toView()
        expect(json.hasDueDate).toBe(false)
        expect(json.hasPointsPossible).toBe(false)
      })

      it('includes fields for isQuiz', () => {
        const assignment = new Assignment({submission_types: ['online_quiz']})
        const json = assignment.toView()
        expect(json.hasDueDate).toBe(true)
        expect(json.hasPointsPossible).toBe(false)
      })
    })

    describe('grading settings', () => {
      it('returns omitFromFinalGrade', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.omitFromFinalGrade(true)
        expect(assignment.toView().omitFromFinalGrade).toBe(true)
      })

      it('returns true when anonymousInstructorAnnotations is true', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.anonymousInstructorAnnotations(true)
        expect(assignment.toView().anonymousInstructorAnnotations).toBe(true)
      })

      it('returns false when anonymousInstructorAnnotations is false', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.anonymousInstructorAnnotations(false)
        expect(assignment.toView().anonymousInstructorAnnotations).toBe(false)
      })
    })
  })

  describe('#singleSection', () => {
    beforeEach(() => {
      fakeENV.setup()
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('returns null when all_dates is null', () => {
      const assignment = new Assignment({})
      jest.spyOn(assignment, 'allDates').mockReturnValue(null)
      expect(assignment.singleSection()).toBeNull()
    })

    it('returns null when there are multiple all_dates records', () => {
      const date = new Date('2022-02-15T11:13:00')
      const assignment = new Assignment({
        all_dates: [
          {
            lock_at: date,
            unlock_at: date,
            due_at: null,
            title: 'Section A',
          },
          {
            lock_at: date,
            unlock_at: date,
            due_at: null,
            title: 'Section B',
          },
          {
            lock_at: date,
            unlock_at: date,
            due_at: null,
            title: 'Section C',
          },
        ],
      })
      expect(assignment.singleSection()).toBeNull()
    })

    it('returns null when there are no records in all_dates', () => {
      const assignment = new Assignment({
        all_dates: [],
      })
      expect(assignment.singleSection()).toBeNull()
    })

    it('returns the first element in all_dates when the length is 1', () => {
      const assignment = new Assignment({
        all_dates: [
          {
            lock_at: new Date('2022-02-15T11:13:00'),
            unlock_at: new Date('2022-02-16T11:13:00'),
            due_at: new Date('2022-02-17T11:13:00'),
            title: 'Section A',
          },
        ],
      })
      expect(assignment.singleSection()).toEqual(assignment.allDates()[0])
    })
  })
})
