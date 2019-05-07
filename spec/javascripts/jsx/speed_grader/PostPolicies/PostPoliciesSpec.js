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
import PostPolicies from '../../../../../app/jsx/speed_grader/PostPolicies'

QUnit.module('SpeedGrader PostPolicies', suiteHooks => {
  let $hideTrayMountPoint
  let $postTrayMountPoint
  let afterUpdateSubmission
  let postPolicies
  let updateSubmission

  function expectedAssignment() {
    return {
      anonymizeStudents: false,
      gradesPublished: true,
      id: '2301',
      name: 'Math 1.1'
    }
  }

  suiteHooks.beforeEach(() => {
    $hideTrayMountPoint = document.createElement('div')
    $postTrayMountPoint = document.createElement('div')
    $hideTrayMountPoint.id = 'hide-assignment-grades-tray'
    $postTrayMountPoint.id = 'post-assignment-grades-tray'

    document.body.appendChild($hideTrayMountPoint)
    document.body.appendChild($postTrayMountPoint)

    const sections = [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}]
    afterUpdateSubmission = sinon.stub()
    updateSubmission = sinon.stub()
    postPolicies = new PostPolicies({
      afterUpdateSubmission,
      assignment: expectedAssignment(),
      sections,
      updateSubmission
    })
  })

  suiteHooks.afterEach(() => {
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

  QUnit.module('#destroy', () => {
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

  QUnit.module('#showHideAssignmentGradesTray', hooks => {
    function hideGradesShowArgs() {
      return postPolicies._hideAssignmentGradesTray.show.firstCall.args[0]
    }

    hooks.beforeEach(() => {
      sinon.stub(postPolicies._hideAssignmentGradesTray, 'show')
    })

    test('calls "show" for the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({})
      strictEqual(postPolicies._hideAssignmentGradesTray.show.callCount, 1)
    })

    test('passes the assignment to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const {assignment} = hideGradesShowArgs()
      deepEqual(assignment, expectedAssignment())
    })

    test('passes the sections to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const {sections} = hideGradesShowArgs()
      deepEqual(sections, [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])
    })

    test('passes updateSubmission to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({
        submissionsMap: {
          '1': {posted_at: new Date().toISOString()}
        }
      })
      const {onHidden} = hideGradesShowArgs()
      onHidden({userIds: ['1']})
      strictEqual(updateSubmission.callCount, 1)
    })

    test('passes afterUpdateSubmission to "show"', () => {
      postPolicies.showHideAssignmentGradesTray({
        submissionsMap: {'1': {posted_at: new Date().toISOString()}}
      })
      const {onHidden} = hideGradesShowArgs()
      onHidden({userIds: ['1']})
      strictEqual(afterUpdateSubmission.callCount, 1)
    })

    test('onHidden updates posted_at', () => {
      const submissionsMap = {
        '1': {posted_at: new Date().toISOString()}
      }
      postPolicies.showHideAssignmentGradesTray({submissionsMap})
      const {onHidden} = hideGradesShowArgs()
      onHidden({postedAt: null, userIds: ['1']})
      strictEqual(submissionsMap['1'].posted_at, null)
    })
  })

  QUnit.module('#showPostAssignmentGradesTray', hooks => {
    function postGradesShowArgs() {
      return postPolicies._postAssignmentGradesTray.show.firstCall.args[0]
    }

    hooks.beforeEach(() => {
      sinon.stub(postPolicies._postAssignmentGradesTray, 'show')
    })

    test('calls "show" for the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({})
      strictEqual(postPolicies._postAssignmentGradesTray.show.callCount, 1)
    })

    test('passes the assignment to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const {assignment} = postGradesShowArgs()
      deepEqual(assignment, expectedAssignment())
    })

    test('passes sections to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const {sections} = postGradesShowArgs()
      deepEqual(sections, [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])
    })

    test('passes submissions to "show"', () => {
      const submission = {
        id: '93',
        assignment_id: '2301',
        posted_at: new Date().toISOString(),
        user_id: '441'
      }
      postPolicies.showPostAssignmentGradesTray({submissions: [submission]})
      const {submissions} = postGradesShowArgs()
      deepEqual(submissions, [submission])
    })

    test('passes updateSubmission to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({submissionsMap: {'1': {posted_at: null}}})
      const {onPosted} = postGradesShowArgs()
      onPosted({userIds: ['1']})
      strictEqual(updateSubmission.callCount, 1)
    })

    test('passes afterUpdateSubmission to "show"', () => {
      postPolicies.showPostAssignmentGradesTray({submissionsMap: {'1': {posted_at: null}}})
      const {onPosted} = postGradesShowArgs()
      onPosted({userIds: ['1']})
      strictEqual(afterUpdateSubmission.callCount, 1)
    })

    test('onPosted updates posted_at', () => {
      const submissionsMap = {
        '1': {posted_at: null}
      }
      postPolicies.showPostAssignmentGradesTray({submissionsMap})
      const postedAt = new Date().toISOString()
      const {onPosted} = postGradesShowArgs()
      onPosted({postedAt, userIds: ['1']})
      strictEqual(submissionsMap['1'].posted_at, postedAt)
    })
  })
})
