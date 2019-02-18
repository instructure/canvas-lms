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

import {
  createGradebook,
  setFixtureHtml
} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook PostPolicies', suiteHooks => {
  let $container
  let gradebook
  let gradebookOptions
  let postPolicies

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)

    gradebookOptions = {
      post_policies_enabled: true
    }
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  function createPostPolicies() {
    gradebook = createGradebook(gradebookOptions)
    postPolicies = gradebook.postPolicies
  }

  QUnit.module('#initialize()', () => {
    test('renders the "Post Assignment Grades" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, true)
    })
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the "Post Assignment Grades" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      postPolicies.destroy()
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })
  })

  QUnit.module('#showPostAssignmentGradesTray()', hooks => {
    hooks.beforeEach(() => {
      createPostPolicies()

      const assignment = {
        anonymize_students: false,
        course_id: '1201',
        html_url: 'http://localhost/assignments/2301',
        id: '2301',
        invalid: false,
        muted: false,
        name: 'Math 1.1',
        omit_from_final_grade: false,
        points_possible: 10,
        published: true,
        submission_types: ['online_text_entry']
      }
      gradebook.setAssignments({2301: assignment})

      postPolicies.initialize()
      sinon.stub(postPolicies._tray, 'show')
    })

    test('shows the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      strictEqual(postPolicies._tray.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._tray.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._tray.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the `onExited` callback when showing the "Post Assignment Grades" tray', () => {
      const callback = sinon.stub()
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301', onExited: callback})
      const [{onExited}] = postPolicies._tray.show.lastCall.args
      strictEqual(onExited, callback)
    })
  })
})
