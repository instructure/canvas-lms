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

import {createGradebook} from '../../default_gradebook/__tests__/GradebookSpecHelper'
import AsyncComponents from '../../default_gradebook/AsyncComponents'
import HideAssignmentGradesTray from '@canvas/hide-assignment-grades-tray'

describe('Gradebook PostPolicies', () => {
  let container
  let gradebook
  let gradebookOptions
  let postPolicies

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    gradebookOptions = {}

    // Set up required DOM elements for trays
    const hideContainer = document.createElement('div')
    hideContainer.id = 'hide-assignment-grades-tray'
    const postContainer = document.createElement('div')
    postContainer.id = 'post-assignment-grades-tray'
    const policyContainer = document.createElement('div')
    policyContainer.id = 'assignment-posting-policy-tray'

    document.body.appendChild(hideContainer)
    document.body.appendChild(postContainer)
    document.body.appendChild(policyContainer)
  })

  afterEach(() => {
    gradebook?.destroy()
    container.remove()
    document.getElementById('hide-assignment-grades-tray')?.remove()
    document.getElementById('post-assignment-grades-tray')?.remove()
    document.getElementById('assignment-posting-policy-tray')?.remove()
  })

  const createPostPolicies = () => {
    gradebook = createGradebook(gradebookOptions)
    postPolicies = gradebook.postPolicies
  }

  describe('destroy()', () => {
    it('unmounts all trays', () => {
      createPostPolicies()
      const unmountSpy = jest.spyOn(document, 'getElementById')
      postPolicies.destroy()

      expect(unmountSpy).toHaveBeenCalledWith('hide-assignment-grades-tray')
      expect(unmountSpy).toHaveBeenCalledWith('post-assignment-grades-tray')
      expect(unmountSpy).toHaveBeenCalledWith('assignment-posting-policy-tray')
    })
  })

  describe('showHideAssignmentGradesTray()', () => {
    let assignment
    let submission

    beforeEach(() => {
      createPostPolicies()

      assignment = {
        anonymous_grading: false,
        course_id: '1201',
        grades_published: true,
        html_url: 'http://localhost/assignments/2301',
        id: '2301',
        invalid: false,
        muted: false,
        name: 'Math 1.1',
        omit_from_final_grade: false,
        points_possible: 10,
        published: true,
        submission_types: ['online_text_entry'],
        visible_to_everyone: true,
      }

      submission = {
        assignment_id: '2301',
        has_postable_comments: true,
        posted_at: new Date('2024-12-09T04:56:04-07:00').toISOString(),
        score: 1.0,
        workflow_state: 'graded',
      }

      const student = {
        name: 'John Doe',
        assignment_2301: submission,
        enrollments: [{type: 'StudentEnrollment', user_id: '441', course_section_id: '1'}],
      }

      gradebook.setAssignments({2301: assignment})
      gradebook.gotChunkOfStudents([student])
      gradebook.setSections([
        {id: '2001', name: 'Hogwarts'},
        {id: '2002', name: 'Freshmen'},
      ])

      jest
        .spyOn(AsyncComponents, 'loadHideAssignmentGradesTray')
        .mockResolvedValue(HideAssignmentGradesTray)
      jest.spyOn(HideAssignmentGradesTray.prototype, 'show').mockImplementation(function (params) {
        return params
      })
    })

    it('renders the Hide Assignment Grades tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      expect(document.getElementById('hide-assignment-grades-tray')).toBeTruthy()
    })

    it('shows the Hide Assignment Grades tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      expect(HideAssignmentGradesTray.prototype.show).toHaveBeenCalled()
    })

    it('includes the assignment id when showing the tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const showCall = HideAssignmentGradesTray.prototype.show.mock.calls[0][0]
      expect(showCall.assignment.id).toBe('2301')
    })

    it('includes the assignment name when showing the tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const showCall = HideAssignmentGradesTray.prototype.show.mock.calls[0][0]
      expect(showCall.assignment.name).toBe('Math 1.1')
    })

    it('includes the assignment anonymous_grading status', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const showCall = HideAssignmentGradesTray.prototype.show.mock.calls[0][0]
      expect(showCall.assignment.anonymousGrading).toBe(false)
    })

    it('includes the assignment grades_published status', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const showCall = HideAssignmentGradesTray.prototype.show.mock.calls[0][0]
      expect(showCall.assignment.gradesPublished).toBe(true)
    })

    it('includes the sections', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const showCall = HideAssignmentGradesTray.prototype.show.mock.calls[0][0]
      expect(showCall.sections).toEqual([
        {id: '2001', name: 'Hogwarts'},
        {id: '2002', name: 'Freshmen'},
      ])
    })

    it('includes the submissions', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const showCall = HideAssignmentGradesTray.prototype.show.mock.calls[0][0]
      expect(showCall.submissions).toEqual([
        {
          hasPostableComments: true,
          postedAt: submission.posted_at,
          score: 1,
          workflowState: 'graded',
        },
      ])
    })

    describe('when grades are hidden', () => {
      beforeEach(() => {
        gradebook.updateSubmission = jest.fn()
        gradebook.handleSubmissionPostedChange = jest.fn()
        gradebook.getSubmission = jest.fn().mockReturnValue({
          posted_at: submission.posted_at,
          score: submission.score,
          workflow_state: submission.workflow_state,
        })
      })

      it('updates the submission in the gradebook', async () => {
        await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const {onHidden} = HideAssignmentGradesTray.prototype.show.mock.results[0].value
        onHidden({assignmentId: '2301', postedAt: null, userIds: ['441']})
        expect(gradebook.getSubmission).toHaveBeenCalledWith('441', '2301')
        expect(gradebook.updateSubmission).toHaveBeenCalledWith({
          posted_at: null,
          score: 1,
          workflow_state: 'graded',
        })
      })
    })
  })

  describe('coursePostPolicy', () => {
    describe('postManually', () => {
      it('is set to true if gradebook.options.post_manually is true on initialization', () => {
        gradebookOptions.post_manually = true
        createPostPolicies()
        expect(postPolicies.coursePostPolicy.postManually).toBe(true)
      })

      it('is set to false if gradebook.options.post_manually is false on initialization', () => {
        gradebookOptions.post_manually = false
        createPostPolicies()
        expect(postPolicies.coursePostPolicy.postManually).toBe(false)
      })
    })
  })
})
