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
    test('renders the "Hide Assignment Grades" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      const $trayContainer = document.getElementById('hide-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, true)
    })

    test('renders the "Post Assignment Grades" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, true)
    })

    test('renders the assignment "Grade Posting Policy" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      const $trayContainer = document.getElementById('assignment-posting-policy-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, true)
    })
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the "Hide Assignment Grades" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      postPolicies.destroy()
      const $trayContainer = document.getElementById('hide-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })

    test('unmounts the "Post Assignment Grades" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      postPolicies.destroy()
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })

    test('unmounts the assignment "Grade Posting Policy" tray', () => {
      createPostPolicies()
      postPolicies.initialize()
      postPolicies.destroy()
      const $trayContainer = document.getElementById('assignment-posting-policy-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, false)
    })
  })

  QUnit.module('#showHideAssignmentGradesTray()', hooks => {
    hooks.beforeEach(() => {
      createPostPolicies()

      const assignment = {
        anonymize_students: false,
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
        submission_types: ['online_text_entry']
      }
      gradebook.setAssignments({2301: assignment})
      gradebook.setSections([{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])

      postPolicies.initialize()
      sinon.stub(postPolicies._hideAssignmentGradesTray, 'show')
    })

    test('shows the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      strictEqual(postPolicies._hideAssignmentGradesTray.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Hide Assignment Grades" tray', () => {
      postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the assignment anonymize_students', () => {
      postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.anonymizeStudents, false)
    })

    test('includes the assignment grades_published', () => {
      postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.gradesPublished, true)
    })

    test('includes the sections', () => {
      postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{sections}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      deepEqual(sections, [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])
    })

    test('includes the `onExited` callback when showing the "Hide Assignment Grades" tray', () => {
      const callback = sinon.stub()
      postPolicies.showHideAssignmentGradesTray({assignmentId: '2301', onExited: callback})
      const [{onExited}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
      strictEqual(onExited, callback)
    })

    QUnit.module('onHidden', onHiddenHooks => {
      let postedOrHiddenInfo
      let student
      let updateColumnHeadersStub

      onHiddenHooks.beforeEach(() => {
        student = {
          assignment_2301: {assignment_id: '2301', user_id: '1101'},
          enrollments: [{type: 'StudentEnrollment'}],
          id: '1101'
        }
        postedOrHiddenInfo = {
          assignmentId: '2301',
          postedAt: null,
          userIds: ['1101']
        }

        gradebook.gotChunkOfStudents([student])
        updateColumnHeadersStub = sinon.stub(gradebook, 'updateColumnHeaders')
      })

      onHiddenHooks.afterEach(() => {
        updateColumnHeadersStub.restore()
      })

      test('calls updateColumnHeaders', () => {
        postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const [{onHidden}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        strictEqual(updateColumnHeadersStub.callCount, 1)
      })

      test('calls updateColumnHeaders with the column ids', () => {
        postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const columnId = gradebook.getAssignmentColumnId('2301')
        const [{onHidden}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        deepEqual(updateColumnHeadersStub.firstCall.args[0], [columnId])
      })

      test('updates the posted_at of the submissions', () => {
        postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const [{onHidden}] = postPolicies._hideAssignmentGradesTray.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        strictEqual(gradebook.getSubmission('1101', '2301').posted_at, postedOrHiddenInfo.postedAt)
      })
    })
  })

  QUnit.module('#showPostAssignmentGradesTray()', hooks => {
    let submission

    hooks.beforeEach(() => {
      createPostPolicies()

      const assignment = {
        anonymize_students: false,
        course_id: '1201',
        grades_published: true,
        id: '2301',
        name: 'Math 1.1'
      }
      submission = {
        assignment_id: '2301',
        posted_at: new Date().toISOString()
      }
      const student = {
        assignment_2301: submission,
        enrollments: [{type: 'StudentEnrollment', user_id: '441', course_section_id: '1'}]
      }

      gradebook.setAssignments({2301: assignment})
      gradebook.gotChunkOfStudents([student])
      gradebook.setSections([{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])

      postPolicies.initialize()
      sinon.stub(postPolicies._postAssignmentGradesTray, 'show')
    })

    test('shows the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      strictEqual(postPolicies._postAssignmentGradesTray.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the assignment anonymize_students', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.anonymizeStudents, false)
    })

    test('includes the assignment grades_published', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(assignment.gradesPublished, true)
    })

    test('includes the sections', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{sections}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      deepEqual(sections, [{id: '2001', name: 'Hogwarts'}, {id: '2002', name: 'Freshmen'}])
    })

    test('includes the submissions', () => {
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{submissions}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      deepEqual(submissions, [{postedAt: submission.posted_at}])
    })

    test('includes the `onExited` callback when showing the "Post Assignment Grades" tray', () => {
      const callback = sinon.stub()
      postPolicies.showPostAssignmentGradesTray({assignmentId: '2301', onExited: callback})
      const [{onExited}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
      strictEqual(onExited, callback)
    })

    QUnit.module('onPosted', onPostedHooks => {
      let postedOrHiddenInfo
      let student
      let updateColumnHeadersStub

      onPostedHooks.beforeEach(() => {
        student = {
          assignment_2301: {assignment_id: '2301', user_id: '1101'},
          enrollments: [{type: 'StudentEnrollment'}],
          id: '1101'
        }
        postedOrHiddenInfo = {
          assignmentId: '2301',
          postedAt: new Date().toISOString(),
          userIds: ['1101']
        }

        gradebook.gotChunkOfStudents([student])
        updateColumnHeadersStub = sinon.stub(gradebook, 'updateColumnHeaders')
      })

      onPostedHooks.afterEach(() => {
        updateColumnHeadersStub.restore()
      })

      test('calls updateColumnHeaders', () => {
        postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const [{onPosted}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        strictEqual(updateColumnHeadersStub.callCount, 1)
      })

      test('calls updateColumnHeaders with the column ids', () => {
        postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const columnId = gradebook.getAssignmentColumnId('2301')
        const [{onPosted}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        deepEqual(updateColumnHeadersStub.firstCall.args[0], [columnId])
      })

      test('updates the posted_at of the submissions', () => {
        postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const [{onPosted}] = postPolicies._postAssignmentGradesTray.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        strictEqual(gradebook.getSubmission('1101', '2301').posted_at, postedOrHiddenInfo.postedAt)
      })
    })
  })

  QUnit.module('#showAssignmentPostingPolicyTray()', hooks => {
    hooks.beforeEach(() => {
      createPostPolicies()

      const assignment = {
        anonymize_students: false,
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
        submission_types: ['online_text_entry']
      }
      gradebook.setAssignments({2301: assignment})

      postPolicies.initialize()
      sinon.stub(postPolicies._assignmentPolicyTray, 'show')
    })

    test('shows the assignment "Grade Posting Policy" tray', () => {
      postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      strictEqual(postPolicies._assignmentPolicyTray.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._assignmentPolicyTray.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Post Assignment Grades" tray', () => {
      postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = postPolicies._assignmentPolicyTray.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the `onExited` callback when showing the "Post Assignment Grades" tray', () => {
      const callback = sinon.stub()
      postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301', onExited: callback})
      const [{onExited}] = postPolicies._assignmentPolicyTray.show.lastCall.args
      strictEqual(onExited, callback)
    })
  })

  QUnit.module('#coursePostPolicy', () => {
    QUnit.module('.postManually', () => {
      test('is set to true if gradebook.options.post_manually is true on initialization', () => {
        gradebookOptions.post_manually = true

        createPostPolicies()
        strictEqual(postPolicies.coursePostPolicy.postManually, true)
      })

      test('is set to false if gradebook.options.post_manually is false on initialization', () => {
        gradebookOptions.post_manually = false

        createPostPolicies()
        strictEqual(postPolicies.coursePostPolicy.postManually, false)
      })

      test('is set to false if gradebook.options.post_manually is not present on initialization', () => {
        createPostPolicies()
        strictEqual(postPolicies.coursePostPolicy.postManually, false)
      })
    })

    test('reflects the value set by setCoursePostPolicy()', () => {
      createPostPolicies()
      postPolicies.setCoursePostPolicy({postManually: false})
      deepEqual(postPolicies.coursePostPolicy, {postManually: false})
    })
  })
})
