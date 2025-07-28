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

import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'

describe('Assignment', () => {
  beforeEach(() => {
    $.ajaxJSON = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('#retry_migration', () => {
    it('makes ajax call with correct url', () => {
      const assignmentID = '200'
      const originalQuizID = '42'
      const courseID = '123'
      const assignment = new Assignment({
        name: 'foo',
        id: assignmentID,
        original_quiz_id: originalQuizID,
        course_id: courseID,
      })

      assignment.retry_migration()

      expect($.ajaxJSON).toHaveBeenCalledWith(
        `/api/v1/courses/${courseID}/content_exports?export_type=quizzes2&quiz_id=${originalQuizID}&failed_assignment_id=${assignmentID}&include[]=migrated_assignment`,
        'POST',
        {},
        undefined,
      )
    })
  })

  describe('#pollUntilFinishedDuplicating', () => {
    let assignment
    let clock

    beforeEach(() => {
      clock = jest.useFakeTimers()
      assignment = new Assignment({workflow_state: 'duplicating'})
      const dfd = $.Deferred()
      dfd.resolve()
      jest.spyOn(assignment, 'fetch').mockReturnValue(dfd)
    })

    afterEach(() => {
      clock.clearAllTimers()
      jest.useRealTimers()
      jest.restoreAllMocks()
    })

    it('polls for updates', () => {
      assignment.pollUntilFinishedDuplicating()
      jest.advanceTimersByTime(2000)
      expect(assignment.fetch).not.toHaveBeenCalled()
      jest.advanceTimersByTime(2000)
      expect(assignment.fetch).toHaveBeenCalled()
    })

    it('stops polling when the assignment has finished duplicating', () => {
      assignment.pollUntilFinishedDuplicating()
      assignment.set({workflow_state: 'unpublished'})
      jest.advanceTimersByTime(3000)
      expect(assignment.fetch).toHaveBeenCalledTimes(1)
      jest.advanceTimersByTime(3000)
      expect(assignment.fetch).toHaveBeenCalledTimes(1)
    })
  })

  describe('#pollUntilFinishedImporting', () => {
    let assignment
    let clock

    beforeEach(() => {
      clock = jest.useFakeTimers()
      assignment = new Assignment({workflow_state: 'importing'})
      const dfd = $.Deferred()
      dfd.resolve()
      jest.spyOn(assignment, 'fetch').mockReturnValue(dfd)
    })

    afterEach(() => {
      clock.clearAllTimers()
      jest.useRealTimers()
      jest.restoreAllMocks()
    })

    it('polls for updates', () => {
      assignment.pollUntilFinishedImporting()
      jest.advanceTimersByTime(2000)
      expect(assignment.fetch).not.toHaveBeenCalled()
      jest.advanceTimersByTime(2000)
      expect(assignment.fetch).toHaveBeenCalled()
    })

    it('stops polling when the assignment has finished importing', () => {
      assignment.pollUntilFinishedImporting()
      assignment.set({workflow_state: 'unpublished'})
      jest.advanceTimersByTime(3000)
      expect(assignment.fetch).toHaveBeenCalledTimes(1)
      jest.advanceTimersByTime(3000)
      expect(assignment.fetch).toHaveBeenCalledTimes(1)
    })
  })

  describe('#pollUntilFinishedMigrating', () => {
    let assignment
    let clock

    beforeEach(() => {
      clock = jest.useFakeTimers()
      assignment = new Assignment({workflow_state: 'migrating'})
      const dfd = $.Deferred()
      dfd.resolve()
      jest.spyOn(assignment, 'fetch').mockReturnValue(dfd)
    })

    afterEach(() => {
      clock.clearAllTimers()
      jest.useRealTimers()
      jest.restoreAllMocks()
    })

    it('polls for updates', () => {
      assignment.pollUntilFinishedMigrating()
      jest.advanceTimersByTime(2000)
      expect(assignment.fetch).not.toHaveBeenCalled()
      jest.advanceTimersByTime(2000)
      expect(assignment.fetch).toHaveBeenCalled()
    })

    it('stops polling when the assignment has finished migrating', () => {
      assignment.pollUntilFinishedMigrating()
      assignment.set({workflow_state: 'unpublished'})
      jest.advanceTimersByTime(3000)
      expect(assignment.fetch).toHaveBeenCalledTimes(1)
      jest.advanceTimersByTime(3000)
      expect(assignment.fetch).toHaveBeenCalledTimes(1)
    })
  })

  describe('#gradersAnonymousToGraders', () => {
    let assignment

    beforeEach(() => {
      assignment = new Assignment()
    })

    it('returns graders_anonymous_to_graders value when no arguments are passed', () => {
      assignment.set('graders_anonymous_to_graders', true)
      expect(assignment.gradersAnonymousToGraders()).toBe(true)
    })

    it('sets the graders_anonymous_to_graders value when an argument is passed', () => {
      assignment.set('graders_anonymous_to_graders', true)
      assignment.gradersAnonymousToGraders(false)
      expect(assignment.gradersAnonymousToGraders()).toBe(false)
    })
  })

  describe('#graderCommentsVisibleToGraders', () => {
    let assignment

    beforeEach(() => {
      assignment = new Assignment()
    })

    it('returns grader_comments_visible_to_graders value when no arguments are passed', () => {
      assignment.set('grader_comments_visible_to_graders', true)
      expect(assignment.graderCommentsVisibleToGraders()).toBe(true)
    })

    it('sets the grader_comments_visible_to_graders value when an argument is passed', () => {
      assignment.set('grader_comments_visible_to_graders', true)
      assignment.graderCommentsVisibleToGraders(false)
      expect(assignment.graderCommentsVisibleToGraders()).toBe(false)
    })
  })

  describe('#showGradersAnonymousToGradersCheckbox', () => {
    let assignment

    beforeEach(() => {
      assignment = new Assignment()
    })

    it('returns false when grader_comments_visible_to_graders is false', () => {
      assignment.set('grader_comments_visible_to_graders', false)
      expect(assignment.showGradersAnonymousToGradersCheckbox()).toBe(false)
    })

    it('returns false when moderated_grading is false', () => {
      assignment.set('moderated_grading', false)
      expect(assignment.showGradersAnonymousToGradersCheckbox()).toBe(false)
    })

    it('returns false when grader_comments_visible_to_graders is false and moderated_grading is true', () => {
      assignment.set('grader_comments_visible_to_graders', false)
      assignment.set('moderated_grading', true)
      expect(assignment.showGradersAnonymousToGradersCheckbox()).toBe(false)
    })

    it('returns false when grader_comments_visible_to_graders is true and moderated_grading is false', () => {
      assignment.set('grader_comments_visible_to_graders', true)
      assignment.set('moderated_grading', false)
      expect(assignment.showGradersAnonymousToGradersCheckbox()).toBe(false)
    })

    it('returns true when grader_comments_visible_to_graders is true and moderated_grading is true', () => {
      assignment.set('grader_comments_visible_to_graders', true)
      assignment.set('moderated_grading', true)
      expect(assignment.showGradersAnonymousToGradersCheckbox()).toBe(true)
    })
  })
})
