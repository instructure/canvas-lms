/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {unmountComponentAtNode} from 'react-dom'
import PostPolicies from '../index'
import SpeedGraderHelpers from '../../../jquery/speed_grader_helpers'

const ok = x => expect(x).toBeTruthy()
const strictEqual = (x, y) => expect(x).toEqual(y)
const deepEqual = (x, y) => expect(x).toEqual(y)

describe('SpeedGrader PostPolicies', () => {
  let $hideTrayMountPoint
  let $postTrayMountPoint
  let afterUpdateSubmission
  let postPolicies
  let updateSubmission

  function expectedAssignment() {
    return {
      anonymousGrading: false,
      gradesPublished: true,
      id: '2301',
      name: 'Math 1.1',
    }
  }

  beforeEach(() => {
    $hideTrayMountPoint = document.createElement('div')
    $postTrayMountPoint = document.createElement('div')
    $hideTrayMountPoint.id = 'hide-assignment-grades-tray'
    $postTrayMountPoint.id = 'post-assignment-grades-tray'

    document.body.appendChild($hideTrayMountPoint)
    document.body.appendChild($postTrayMountPoint)

    const sections = [
      {id: '2001', name: 'Hogwarts'},
      {id: '2002', name: 'Freshmen'},
    ]
    afterUpdateSubmission = jest.fn()
    updateSubmission = jest.fn()
    postPolicies = new PostPolicies({
      afterUpdateSubmission,
      assignment: expectedAssignment(),
      sections,
      updateSubmission,
    })
  })

  afterEach(() => {
    postPolicies.destroy()
    $postTrayMountPoint.remove()
    $hideTrayMountPoint.remove()
  })

  test('renders the "Hide Assignment Grades" tray', () => {
    const $trayContainer = document.getElementById('hide-assignment-grades-tray')
    const unmounted = unmountComponentAtNode($trayContainer)
    strictEqual(unmounted, true)
  })

  test('renders the "Post Assignment Grades" tray', () => {
    const $trayContainer = document.getElementById('post-assignment-grades-tray')
    const unmounted = unmountComponentAtNode($trayContainer)
    strictEqual(unmounted, true)
  })

  describe('#destroy', () => {
    test('unmounts the "Hide Assignment Grades" tray', () => {
      postPolicies.destroy()
      const $trayContainer = document.getElementById('hide-assignment-grades-tray')
      const unmounted = unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })

    test('unmounts the "Post Assignment Grades" tray', () => {
      postPolicies.destroy()
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounted = unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })
  })

  describe('#showHideAssignmentGradesTray', () => {
    function hideGradesShowArgs() {
      return postPolicies._hideAssignmentGradesTray.show.mock.calls[0][0]
    }

    beforeEach(() => {
      jest.spyOn(postPolicies._hideAssignmentGradesTray, 'show').mockImplementation(() => {})
    })

    test('calls "show" for the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({})
      expect(postPolicies._hideAssignmentGradesTray.show).toHaveBeenCalledTimes(1)
    })

    test('passes the assignment to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const {assignment} = hideGradesShowArgs()
      deepEqual(assignment, expectedAssignment())
    })

    test('passes the sections to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const {sections} = hideGradesShowArgs()
      deepEqual(sections, [
        {id: '2001', name: 'Hogwarts'},
        {id: '2002', name: 'Freshmen'},
      ])
    })

    test('passes updateSubmission to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({
        submissionsMap: {
          1: {posted_at: new Date().toISOString()},
        },
      })
      const {onHidden} = hideGradesShowArgs()
      onHidden({userIds: ['1']})
      expect(updateSubmission).toHaveBeenCalledTimes(1)
    })

    test('passes afterUpdateSubmission to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({
        submissionsMap: {1: {posted_at: new Date().toISOString()}},
      })
      const {onHidden} = hideGradesShowArgs()
      onHidden({userIds: ['1']})
      expect(afterUpdateSubmission).toHaveBeenCalledTimes(1)
    })

    test('onHidden updates posted_at when assignment anonymousGrading is false', () => {
      const submissionsMap = {
        1: {posted_at: new Date().toISOString()},
      }
      postPolicies.showHideAssignmentGradesTray({submissionsMap})
      const {onHidden} = hideGradesShowArgs()
      onHidden({postedAt: null, userIds: ['1']})
      strictEqual(submissionsMap['1'].posted_at, null)
    })

    test('onHidden does not reload the page when assignment anonymousGrading is false', () => {
      const reloadStub = jest.spyOn(SpeedGraderHelpers, 'reloadPage').mockImplementation(() => {})
      const submissionsMap = {
        1: {posted_at: new Date().toISOString()},
      }
      postPolicies.showHideAssignmentGradesTray({submissionsMap})
      const {onHidden} = hideGradesShowArgs()
      onHidden({postedAt: null, userIds: ['1']})
      expect(reloadStub).not.toHaveBeenCalled()
      reloadStub.mockRestore()
    })

    test('onHidden reloads the page when assignment anonymousGrading is true', () => {
      const reloadStub = jest.spyOn(SpeedGraderHelpers, 'reloadPage').mockImplementation(() => {})
      const submissionsMap = {
        1: {posted_at: new Date().toISOString()},
      }
      postPolicies._assignment.anonymousGrading = true
      postPolicies.showHideAssignmentGradesTray({submissionsMap})
      const {onHidden} = hideGradesShowArgs()
      onHidden()
      expect(reloadStub).toHaveBeenCalledTimes(1)
      reloadStub.mockRestore()
    })

    test('onHidden ignores user IDs that do not match known students', () => {
      const submissionsMap = {
        1: {posted_at: new Date().toISOString()},
      }
      postPolicies.showHideAssignmentGradesTray({submissionsMap})
      const {onHidden} = hideGradesShowArgs()
      onHidden({postedAt: null, userIds: ['1', '1111']})
      ok('onHidden with nonexistent user should not throw an error')
    })
  })

  describe('#showPostAssignmentGradesTray', () => {
    function postGradesShowArgs() {
      return postPolicies._postAssignmentGradesTray.show.mock.calls[0][0]
    }

    beforeEach(() => {
      jest.spyOn(postPolicies._postAssignmentGradesTray, 'show').mockImplementation(() => {})
    })

    test('calls "show" for the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({})
      expect(postPolicies._postAssignmentGradesTray.show).toHaveBeenCalledTimes(1)
    })

    test('passes the assignment to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const {assignment} = postGradesShowArgs()
      deepEqual(assignment, expectedAssignment())
    })

    test('passes sections to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const {sections} = postGradesShowArgs()
      deepEqual(sections, [
        {id: '2001', name: 'Hogwarts'},
        {id: '2002', name: 'Freshmen'},
      ])
    })

    test('passes submissions to "show"', () => {
      const submission = {
        id: '93',
        assignment_id: '2301',
        has_postable_comments: true,
        posted_at: new Date().toISOString(),
        score: 1.0,
        user_id: '441',
        workflow_state: 'graded',
      }
      postPolicies.showPostAssignmentGradesTray({submissions: [submission]})
      const {submissions} = postGradesShowArgs()
      deepEqual(submissions, [
        {
          hasPostableComments: true,
          postedAt: submission.posted_at,
          score: 1.0,
          workflowState: submission.workflow_state,
        },
      ])
    })

    test('passes updateSubmission to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({submissionsMap: {1: {posted_at: null}}})
      const {onPosted} = postGradesShowArgs()
      onPosted({userIds: ['1']})
      expect(updateSubmission).toHaveBeenCalledTimes(1)
    })

    test('passes afterUpdateSubmission to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({submissionsMap: {1: {posted_at: null}}})
      const {onPosted} = postGradesShowArgs()
      onPosted({userIds: ['1']})
      expect(afterUpdateSubmission).toHaveBeenCalledTimes(1)
    })

    test('onPosted updates posted_at when assignment anonymousGrading is false', () => {
      const submissionsMap = {
        1: {posted_at: null},
      }
      postPolicies.showPostAssignmentGradesTray({submissionsMap})
      const postedAt = new Date().toISOString()
      const {onPosted} = postGradesShowArgs()
      onPosted({postedAt, userIds: ['1']})
      strictEqual(submissionsMap['1'].posted_at, postedAt)
    })

    test('onPosted does not reload the page when assignment anonymousGrading is false', () => {
      const reloadStub = jest.spyOn(SpeedGraderHelpers, 'reloadPage').mockImplementation(() => {})
      const submissionsMap = {
        1: {posted_at: null},
      }
      postPolicies.showPostAssignmentGradesTray({submissionsMap})
      const postedAt = new Date().toISOString()
      const {onPosted} = postGradesShowArgs()
      onPosted({postedAt, userIds: ['1']})
      expect(reloadStub).not.toHaveBeenCalled()
      reloadStub.mockRestore()
    })

    test('onPosted reloads the page when assignment anonymousGrading is true', () => {
      const reloadStub = jest.spyOn(SpeedGraderHelpers, 'reloadPage').mockImplementation(() => {})
      const submissionsMap = {
        1: {posted_at: null},
      }
      postPolicies._assignment.anonymousGrading = true
      postPolicies.showPostAssignmentGradesTray({submissionsMap})
      const {onPosted} = postGradesShowArgs()
      onPosted()
      expect(reloadStub).toHaveBeenCalledTimes(1)
      reloadStub.mockRestore()
    })

    test('onPosted ignores user IDs that do not match known students', () => {
      const submissionsMap = {
        1: {posted_at: null},
      }
      postPolicies.showPostAssignmentGradesTray({submissionsMap})
      const postedAt = new Date().toISOString()
      const {onPosted} = postGradesShowArgs()
      onPosted({postedAt, userIds: ['1', '1111']})
      ok('onPosted with nonexistent user should not throw an error')
    })
  })
})
