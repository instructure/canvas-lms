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

import ReactDOM from 'react-dom'
import PostPolicies from '../../../../../app/jsx/speed_grader/PostPolicies'

QUnit.module('SpeedGrader PostPolicies', suiteHooks => {
  let $hideTrayMountPoint
  let $postTrayMountPoint
  let postPolicies

  suiteHooks.beforeEach(() => {
    $hideTrayMountPoint = document.createElement('div')
    $postTrayMountPoint = document.createElement('div')
    $hideTrayMountPoint.id = 'hide-assignment-grades-tray'
    $postTrayMountPoint.id = 'post-assignment-grades-tray'

    document.body.appendChild($hideTrayMountPoint)
    document.body.appendChild($postTrayMountPoint)

    const assignment = {
      anonymizeStudents: false,
      gradesPublished: true,
      id: '2301',
      name: 'Math 1.1'
    }
    const sections = [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}]
    postPolicies = new PostPolicies({assignment, sections})
  })

  suiteHooks.afterEach(() => {
    postPolicies.destroy()
    $postTrayMountPoint.remove()
    $hideTrayMountPoint.remove()
  })

  test('renders the "Hide Assignment Grades" tray', () => {
    const $trayContainer = document.getElementById('hide-assignment-grades-tray')
    const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
    strictEqual(unmounted, true)
  })

  test('renders the "Post Assignment Grades" tray', () => {
    const $trayContainer = document.getElementById('post-assignment-grades-tray')
    const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
    strictEqual(unmounted, true)
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the "Hide Assignment Grades" tray', () => {
      postPolicies.destroy()
      const $trayContainer = document.getElementById('hide-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })

    test('unmounts the "Post Assignment Grades" tray', () => {
      postPolicies.destroy()
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })
  })

  QUnit.module('#showHideAssignmentGradesTray()', hooks => {
    hooks.beforeEach(() => {
      sinon.stub(postPolicies._hideAssignmentGradesTray, 'show')
    })

    test('shows the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({})
      strictEqual(postPolicies._hideAssignmentGradesTray.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the assignment anonymizeStudents', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.anonymizeStudents, false)
    })

    test('includes the assignment gradesPublished', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.gradesPublished, true)
    })

    test('includes the sections', () => {
      postPolicies.showHideAssignmentGradesTray({})
      const [{sections}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      deepEqual(sections, [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])
    })

    test('includes the `onExited` callback when showing the "Hide Assignment Grades" tray', () => {
      const callback = sinon.stub()
      postPolicies.showHideAssignmentGradesTray({onExited: callback})
      const [{onExited}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(onExited, callback)
    })
  })

  QUnit.module('#showPostAssignmentGradesTray()', hooks => {
    hooks.beforeEach(() => {
      sinon.stub(postPolicies._postAssignmentGradesTray, 'show')
    })

    test('shows the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({})
      strictEqual(postPolicies._postAssignmentGradesTray.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the assignment anonymizeStudents', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.anonymizeStudents, false)
    })

    test('includes the assignment gradesPublished', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.gradesPublished, true)
    })

    test('includes the sections', () => {
      postPolicies.showPostAssignmentGradesTray({})
      const [{sections}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      deepEqual(sections, [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])
    })

    test('includes the submissions', () => {
      const submission = {
        id: '93',
        assignment_id: '2301',
        posted_at: new Date().toISOString(),
        user_id: '441'
      }
      postPolicies.showPostAssignmentGradesTray({submissions: [submission]})
      const [{submissions}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      deepEqual(submissions, [submission])
    })

    test('includes the `onExited` callback when showing the "Post Assignment Grades" tray', () => {
      const callback = sinon.stub()
      postPolicies.showPostAssignmentGradesTray({onExited: callback})
      const [{onExited}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(onExited, callback)
    })
  })
})
