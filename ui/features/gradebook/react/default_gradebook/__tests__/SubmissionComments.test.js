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

import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {createGradebook} from './GradebookSpecHelper'
import SubmissionCommentApi from '../apis/SubmissionCommentApi'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

vi.mock('@canvas/alerts/react/FlashAlert')

const server = setupServer()

describe('SubmissionComments', () => {
  let gradebook
  let gridNode

  const assignment = {
    grade_group_students_individually: true,
    group_category_id: '2201',
    id: '2301',
  }
  const student = {
    enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
    id: '1101',
    name: 'Adam Jones',
  }

  beforeEach(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    gridNode = document.createElement('div')
    gradebook = createGradebook({
      gradebookGridNode: gridNode,
    })
    gradebook.setAssignments({2301: assignment})
    gradebook.gotChunkOfStudents([student])
    gradebook.gridData = {
      columns: {
        definitions: {},
        frozen: [],
        scrollable: [],
      },
    }
    gradebook.gradebookGrid = {
      gridSupport: {
        helper: {
          commitCurrentEdit() {},
        },
        state: {
          getActiveLocation() {
            return {cell: 0, row: 0}
          },
        },
        grid: {
          getColumns() {
            return [
              {
                id: 'assignment_2301',
                assignmentId: '2301',
              },
            ]
          },
        },
      },
    }
    gradebook.setSubmissionTrayState(true, student.id, assignment.id)
  })

  afterEach(() => {
    vi.clearAllMocks()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('#updateSubmissionComments', () => {
    beforeEach(() => {
      vi.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
    })

    it('calls renderSubmissionTray', () => {
      gradebook.updateSubmissionComments([])
      expect(gradebook.renderSubmissionTray).toHaveBeenCalled()
    })

    it('sets the edited comment ID to null', () => {
      gradebook.setEditedCommentId('5')
      gradebook.updateSubmissionComments([])
      expect(gradebook.getSubmissionTrayState().editedCommentId).toBeNull()
    })
  })

  describe('#unloadSubmissionComments', () => {
    it('calls setSubmissionComments with empty collection', () => {
      const setSubmissionCommentsMock = vi.spyOn(gradebook, 'setSubmissionComments')
      gradebook.unloadSubmissionComments()
      expect(setSubmissionCommentsMock).toHaveBeenCalledWith([])
    })

    it('sets submission comments as not loaded', () => {
      const setSubmissionCommentsLoadedMock = vi.spyOn(gradebook, 'setSubmissionCommentsLoaded')
      gradebook.unloadSubmissionComments()
      expect(setSubmissionCommentsLoadedMock).toHaveBeenCalledWith(false)
    })
  })

  describe('#apiCreateSubmissionComment', () => {
    beforeEach(() => {
      vi.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
      server.use(
        http.put('/api/v1/courses/*/assignments/*/submissions/*', () => {
          return HttpResponse.json({
            submission_comments: [
              {
                id: 1,
                comment: 'a comment',
                created_at: '2024-01-01T00:00:00Z',
              },
            ],
          })
        })
      )
    })

    it('updates submission comments on successful API call', async () => {
      vi.spyOn(gradebook, 'updateSubmissionComments')
      await gradebook.apiCreateSubmissionComment('a comment')
      expect(gradebook.updateSubmissionComments).toHaveBeenCalled()
    })

    it('shows success flash message on successful API call', async () => {
      await gradebook.apiCreateSubmissionComment('a comment')
      expect(FlashAlert.showFlashSuccess).toHaveBeenCalled()
    })

    it('shows error flash message on failed API call', async () => {
      server.use(
        http.put('/api/v1/courses/*/assignments/*/submissions/*', () => {
          return new HttpResponse(null, {status: 500})
        })
      )
      await gradebook.apiCreateSubmissionComment('a comment')
      expect(FlashAlert.showFlashError).toHaveBeenCalled()
    })

    it('includes correct data in API call for individual assignment', async () => {
      const createSubmissionCommentSpy = vi.spyOn(SubmissionCommentApi, 'createSubmissionComment')
      await gradebook.apiCreateSubmissionComment('a comment')

      expect(createSubmissionCommentSpy).toHaveBeenCalledWith(
        expect.anything(),
        '2301',
        expect.anything(),
        expect.objectContaining({
          text_comment: 'a comment',
          group_comment: 0,
        }),
      )
    })

    it('includes attempt in API call when submission has attempt', async () => {
      vi.spyOn(gradebook, 'getSubmission').mockReturnValue({attempt: 3})
      const createSubmissionCommentSpy = vi.spyOn(SubmissionCommentApi, 'createSubmissionComment')

      await gradebook.apiCreateSubmissionComment('a comment')

      expect(createSubmissionCommentSpy).toHaveBeenCalledWith(
        expect.anything(),
        expect.anything(),
        expect.anything(),
        expect.objectContaining({
          attempt: 3,
        }),
      )
    })

    describe('group assignments', () => {
      it('sets group_comment to 1 when not grading individually', async () => {
        const groupAssignment = {...assignment, grade_group_students_individually: false}
        gradebook.setAssignments({2301: groupAssignment})

        const createSubmissionCommentSpy = vi.spyOn(
          SubmissionCommentApi,
          'createSubmissionComment',
        )
        await gradebook.apiCreateSubmissionComment('a comment')

        expect(createSubmissionCommentSpy).toHaveBeenCalledWith(
          expect.anything(),
          expect.anything(),
          expect.anything(),
          expect.objectContaining({
            group_comment: 1,
          }),
        )
      })
    })
  })

  describe('submission comments state', () => {
    it('initializes with empty comments', () => {
      expect(gradebook.getSubmissionComments()).toEqual([])
    })

    it('can set and get comments', () => {
      const comments = ['comment1']
      gradebook.setSubmissionComments(comments)
      expect(gradebook.getSubmissionComments()).toEqual(comments)
    })
  })
})
