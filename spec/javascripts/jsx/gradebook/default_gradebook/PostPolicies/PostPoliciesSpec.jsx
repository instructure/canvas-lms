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
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import AsyncComponents from 'ui/features/gradebook/react/default_gradebook/AsyncComponents'
import HideAssignmentGradesTray from '@canvas/hide-assignment-grades-tray'
import PostAssignmentGradesTray from '@canvas/post-assignment-grades-tray'
import AssignmentPostingPolicyTray from 'ui/features/gradebook/react/AssignmentPostingPolicyTray/index'
import {getAssignmentColumnId} from 'ui/features/gradebook/react/default_gradebook/Gradebook.utils'

QUnit.module('Gradebook PostPolicies', suiteHooks => {
  let $container
  let gradebook
  let gradebookOptions
  let postPolicies

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)

    gradebookOptions = {}
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  function createPostPolicies() {
    gradebook = createGradebook(gradebookOptions)
    postPolicies = gradebook.postPolicies
  }

  QUnit.module('#destroy()', () => {
    test('unmounts the "Hide Assignment Grades" tray', () => {
      createPostPolicies()
      sandbox.spy(ReactDOM, 'unmountComponentAtNode')
      postPolicies.destroy()
      const $trayContainer = document.getElementById('hide-assignment-grades-tray')
      const unmounts = ReactDOM.unmountComponentAtNode
        .getCalls()
        .filter(call => call.args[0] === $trayContainer)
      strictEqual(unmounts.length, 1)
    })

    test('unmounts the "Post Assignment Grades" tray', () => {
      createPostPolicies()
      sandbox.spy(ReactDOM, 'unmountComponentAtNode')
      postPolicies.destroy()
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounts = ReactDOM.unmountComponentAtNode
        .getCalls()
        .filter(call => call.args[0] === $trayContainer)
      strictEqual(unmounts.length, 1)
    })

    test('unmounts the assignment "Grade Posting Policy" tray', () => {
      createPostPolicies()
      sandbox.spy(ReactDOM, 'unmountComponentAtNode')
      postPolicies.destroy()
      const $trayContainer = document.getElementById('assignment-posting-policy-tray')
      const unmounts = ReactDOM.unmountComponentAtNode
        .getCalls()
        .filter(call => call.args[0] === $trayContainer)
      strictEqual(unmounts.length, 1)
    })
  })

  QUnit.module('#showHideAssignmentGradesTray()', hooks => {
    let assignment
    let submission

    hooks.beforeEach(() => {
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
      }
      submission = {
        assignment_id: '2301',
        has_postable_comments: true,
        posted_at: new Date().toISOString(),
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

      sandbox
        .stub(AsyncComponents, 'loadHideAssignmentGradesTray')
        .returns(Promise.resolve(HideAssignmentGradesTray))
      sandbox.stub(HideAssignmentGradesTray.prototype, 'show')
    })

    hooks.afterEach(() => {
      const $trayContainer = document.getElementById('hide-assignment-grades-tray')
      ReactDOM.unmountComponentAtNode($trayContainer)
    })

    test('renders the "Hide Assignment Grades" tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const $trayContainer = document.getElementById('hide-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, true)
    })

    test('shows the "Hide Assignment Grades" tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      strictEqual(HideAssignmentGradesTray.prototype.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Hide Assignment Grades" tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = HideAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Hide Assignment Grades" tray', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = HideAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the assignment anonymous_grading', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = HideAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.anonymousGrading, false)
    })

    test('includes the assignment grades_published', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = HideAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.gradesPublished, true)
    })

    test('includes the sections', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{sections}] = HideAssignmentGradesTray.prototype.show.lastCall.args
      deepEqual(sections, [
        {id: '2001', name: 'Hogwarts'},
        {id: '2002', name: 'Freshmen'},
      ])
    })

    test('includes the submissions', async () => {
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
      const [{submissions}] = HideAssignmentGradesTray.prototype.show.lastCall.args
      deepEqual(submissions, [
        {
          hasPostableComments: true,
          postedAt: submission.posted_at,
          score: '1',
          workflowState: 'graded',
        },
      ])
    })

    test('includes the `onExited` callback when showing the "Hide Assignment Grades" tray', async () => {
      const callback = sinon.stub()
      await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301', onExited: callback})
      const [{onExited}] = HideAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(onExited, callback)
    })

    QUnit.module('onHidden', onHiddenHooks => {
      let postedOrHiddenInfo
      let student
      let handleSubmissionPostedChangeStub

      onHiddenHooks.beforeEach(() => {
        student = {
          name: 'John Doe',
          assignment_2301: {assignment_id: '2301', user_id: '1101'},
          enrollments: [{type: 'StudentEnrollment'}],
          id: '1101',
        }
        postedOrHiddenInfo = {
          assignmentId: '2301',
          postedAt: null,
          userIds: ['1101'],
        }

        gradebook.gotChunkOfStudents([student])
        handleSubmissionPostedChangeStub = sinon.stub(gradebook, 'handleSubmissionPostedChange')
      })

      onHiddenHooks.afterEach(() => {
        handleSubmissionPostedChangeStub.restore()
      })

      test('calls handleSubmissionPostedChange', async () => {
        await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const [{onHidden}] = HideAssignmentGradesTray.prototype.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        strictEqual(handleSubmissionPostedChangeStub.callCount, 1)
      })

      test('calls handleSubmissionPostedChange with the assignment', async () => {
        await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const [{onHidden}] = HideAssignmentGradesTray.prototype.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        strictEqual(handleSubmissionPostedChangeStub.firstCall.args[0].id, '2301')
      })

      test('updates the assignment anonymize_students when hiding for an anonymous assignment', async () => {
        assignment = {...assignment, anonymize_students: false, anonymous_grading: true}
        gradebook.setAssignments({2301: assignment})
        await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const [{onHidden}] = HideAssignmentGradesTray.prototype.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        strictEqual(gradebook.getAssignment('2301').anonymize_students, true)
      })

      test('updates the posted_at of the submissions', async () => {
        await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const [{onHidden}] = HideAssignmentGradesTray.prototype.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        strictEqual(gradebook.getSubmission('1101', '2301').posted_at, postedOrHiddenInfo.postedAt)
      })

      test('ignores user IDs that do not match known students', async () => {
        postedOrHiddenInfo.userIds.push('9876')
        await postPolicies.showHideAssignmentGradesTray({assignmentId: '2301'})
        const [{onHidden}] = HideAssignmentGradesTray.prototype.show.lastCall.args
        onHidden(postedOrHiddenInfo)
        ok('onHidden with nonexistent user should not throw an error')
      })
    })
  })

  QUnit.module('#showPostAssignmentGradesTray()', hooks => {
    let assignment
    let submission

    hooks.beforeEach(() => {
      createPostPolicies()

      assignment = {
        anonymous_grading: false,
        course_id: '1201',
        grades_published: true,
        id: '2301',
        name: 'Math 1.1',
      }
      submission = {
        assignment_id: '2301',
        has_postable_comments: true,
        posted_at: new Date().toISOString(),
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

      sandbox
        .stub(AsyncComponents, 'loadPostAssignmentGradesTray')
        .returns(Promise.resolve(PostAssignmentGradesTray))
      sandbox.stub(PostAssignmentGradesTray.prototype, 'show')
    })

    hooks.afterEach(() => {
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      ReactDOM.unmountComponentAtNode($trayContainer)
    })

    test('renders the "Post Assignment Grades" tray', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const $trayContainer = document.getElementById('post-assignment-grades-tray')
      const unmounted = ReactDOM.unmountComponentAtNode($trayContainer)
      strictEqual(unmounted, true)
    })

    test('shows the "Post Assignment Grades" tray', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      strictEqual(PostAssignmentGradesTray.prototype.show.callCount, 1)
    })

    test('includes the assignment id when showing the "Post Assignment Grades" tray', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name when showing the "Post Assignment Grades" tray', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('includes the assignment anonymous_grading', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.anonymousGrading, false)
    })

    test('includes the assignment grades_published', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{assignment}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      strictEqual(assignment.gradesPublished, true)
    })

    test('includes the sections', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{sections}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      deepEqual(sections, [
        {id: '2001', name: 'Hogwarts'},
        {id: '2002', name: 'Freshmen'},
      ])
    })

    test('includes the submissions', async () => {
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{submissions}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      deepEqual(submissions, [
        {
          hasPostableComments: true,
          postedAt: submission.posted_at,
          score: '1',
          workflowState: 'graded',
        },
      ])
    })

    test('the `onExited` callback is passed in onExited', async () => {
      const callback = sinon.stub()
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301', onExited: callback})
      const [{onExited}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      onExited()
      strictEqual(callback.callCount, 1)
    })

    test('the `postAssignmentGradesTrayOpenChanged` callback is passed in onExited', async () => {
      const trayOpenOrCloseStub = sinon.stub(gradebook, 'postAssignmentGradesTrayOpenChanged')
      await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
      const [{onExited}] = PostAssignmentGradesTray.prototype.show.lastCall.args
      const existingCallCount = trayOpenOrCloseStub.callCount
      onExited()
      strictEqual(trayOpenOrCloseStub.callCount, existingCallCount + 1)
      trayOpenOrCloseStub.restore()
    })

    QUnit.module('onPosted', onPostedHooks => {
      let postedOrHiddenInfo
      let student
      let handleSubmissionPostedChangeStub

      onPostedHooks.beforeEach(() => {
        student = {
          name: 'John Doe',
          assignment_2301: {assignment_id: '2301', user_id: '1101'},
          enrollments: [{type: 'StudentEnrollment'}],
          id: '1101',
        }
        postedOrHiddenInfo = {
          assignmentId: '2301',
          postedAt: new Date(),
          userIds: ['1101'],
        }

        gradebook.gotChunkOfStudents([student])
        handleSubmissionPostedChangeStub = sinon.stub(gradebook, 'handleSubmissionPostedChange')
      })

      onPostedHooks.afterEach(() => {
        handleSubmissionPostedChangeStub.restore()
      })

      test('calls handleSubmissionPostedChange', async () => {
        await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const [{onPosted}] = PostAssignmentGradesTray.prototype.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        strictEqual(handleSubmissionPostedChangeStub.callCount, 1)
      })

      test('calls handleSubmissionPostedChange with the assignment', async () => {
        await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const [{onPosted}] = PostAssignmentGradesTray.prototype.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        strictEqual(handleSubmissionPostedChangeStub.firstCall.args[0].id, '2301')
      })

      test('updates the assignment anonymize_students when posting for an anonymous assignment', async () => {
        assignment = {...assignment, anonymize_students: true, anonymous_grading: true}
        gradebook.setAssignments({2301: assignment})
        await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const [{onPosted}] = PostAssignmentGradesTray.prototype.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        strictEqual(gradebook.getAssignment('2301').anonymize_students, false)
      })

      test('updates the posted_at of the submissions', async () => {
        await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const [{onPosted}] = PostAssignmentGradesTray.prototype.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        deepEqual(gradebook.getSubmission('1101', '2301').posted_at, postedOrHiddenInfo.postedAt)
      })

      test('ignores user IDs that do not match known students', async () => {
        postedOrHiddenInfo.userIds.push('9876')
        await postPolicies.showPostAssignmentGradesTray({assignmentId: '2301'})
        const [{onPosted}] = PostAssignmentGradesTray.prototype.show.lastCall.args
        onPosted(postedOrHiddenInfo)
        ok('onPosted with nonexistent user should not throw an error')
      })
    })
  })

  QUnit.module('#showAssignmentPostingPolicyTray()', hooks => {
    hooks.beforeEach(() => {
      createPostPolicies()

      const assignment = {
        anonymous_grading: true,
        course_id: '1201',
        grades_published: true,
        html_url: 'http://localhost/assignments/2301',
        id: '2301',
        invalid: false,
        moderated_grading: true,
        muted: false,
        name: 'Math 1.1',
        omit_from_final_grade: false,
        points_possible: 10,
        post_manually: true,
        published: true,
        submission_types: ['online_text_entry'],
      }
      gradebook.setAssignments({2301: assignment})

      sandbox
        .stub(AsyncComponents, 'loadAssignmentPostingPolicyTray')
        .returns(Promise.resolve(AssignmentPostingPolicyTray))
      sandbox.stub(AssignmentPostingPolicyTray.prototype, 'show')
    })

    test('shows the assignment "Grade Posting Policy" tray', async () => {
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      strictEqual(AssignmentPostingPolicyTray.prototype.show.callCount, 1)
    })

    test('includes the assignment id', async () => {
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = AssignmentPostingPolicyTray.prototype.show.lastCall.args
      strictEqual(assignment.id, '2301')
    })

    test('includes the assignment name', async () => {
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = AssignmentPostingPolicyTray.prototype.show.lastCall.args
      strictEqual(assignment.name, 'Math 1.1')
    })

    test('passes the assignment anonymous-grading status to the tray', async () => {
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = AssignmentPostingPolicyTray.prototype.show.lastCall.args
      strictEqual(assignment.anonymousGrading, true)
    })

    test('passes the assignment moderated-grading status to the tray', async () => {
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = AssignmentPostingPolicyTray.prototype.show.lastCall.args
      strictEqual(assignment.moderatedGrading, true)
    })

    test('passes the assignment grades-published status to the tray', async () => {
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = AssignmentPostingPolicyTray.prototype.show.lastCall.args
      strictEqual(assignment.gradesPublished, true)
    })

    test('passes the current manual-posting status of the assignment to the tray', async () => {
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
      const [{assignment}] = AssignmentPostingPolicyTray.prototype.show.lastCall.args
      strictEqual(assignment.postManually, true)
    })

    test('includes the `onExited` callback', async () => {
      const callback = sinon.stub()
      await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301', onExited: callback})
      const [{onExited}] = AssignmentPostingPolicyTray.prototype.show.lastCall.args
      strictEqual(onExited, callback)
    })

    QUnit.module('onAssignmentPostPolicyUpdated', onUpdateHooks => {
      let updateColumnHeadersStub

      onUpdateHooks.beforeEach(() => {
        updateColumnHeadersStub = sinon.stub(gradebook, 'updateColumnHeaders')
      })

      onUpdateHooks.afterEach(() => {
        updateColumnHeadersStub.restore()
      })

      test('calls updateColumnHeaders', async () => {
        await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
        const [{onAssignmentPostPolicyUpdated}] =
          AssignmentPostingPolicyTray.prototype.show.lastCall.args
        onAssignmentPostPolicyUpdated({assignmentId: '2301', postManually: true})
        strictEqual(updateColumnHeadersStub.callCount, 1)
      })

      test('calls updateColumnHeaders with the column ID of the affected assignment', async () => {
        await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
        const columnId = getAssignmentColumnId('2301')
        const [{onAssignmentPostPolicyUpdated}] =
          AssignmentPostingPolicyTray.prototype.show.lastCall.args
        onAssignmentPostPolicyUpdated({assignmentId: '2301', postManually: true})
        deepEqual(updateColumnHeadersStub.firstCall.args[0], [columnId])
      })

      test('updates the post_manually field of the assignment', async () => {
        await postPolicies.showAssignmentPostingPolicyTray({assignmentId: '2301'})
        const [{onAssignmentPostPolicyUpdated}] =
          AssignmentPostingPolicyTray.prototype.show.lastCall.args
        onAssignmentPostPolicyUpdated({assignmentId: '2301', postManually: false})
        deepEqual(gradebook.getAssignment('2301').post_manually, false)
      })
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

  QUnit.module('#setCoursePostPolicy', hooks => {
    hooks.beforeEach(() => {
      createPostPolicies()
    })

    test('sets the course post policy', () => {
      createPostPolicies()
      postPolicies.setCoursePostPolicy({postManually: true})
      deepEqual(postPolicies.coursePostPolicy, {postManually: true})
    })
  })

  QUnit.module('#setAssignmentPostPolicies', hooks => {
    hooks.beforeEach(() => {
      createPostPolicies()

      const assignment1 = {
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
        post_manually: false,
        published: true,
        submission_types: ['online_text_entry'],
      }

      const assignment2 = {
        anonymous_grading: false,
        course_id: '1201',
        grades_published: true,
        html_url: 'http://localhost/assignments/2301',
        id: '2302',
        invalid: false,
        muted: false,
        name: 'Math 1.2',
        omit_from_final_grade: false,
        points_possible: 10,
        post_manually: false,
        published: true,
        submission_types: ['online_text_entry'],
      }

      gradebook.setAssignments({2301: assignment1, 2302: assignment2})
    })

    test('updates the post_manually values for assignments given in assignmentPostPoliciesById', () => {
      const assignmentPostPoliciesById = {
        2301: {postManually: true},
        2302: {postManually: true},
      }

      postPolicies.setAssignmentPostPolicies({assignmentPostPoliciesById})
      strictEqual(gradebook.getAssignment('2301').post_manually, true)
    })

    test('does not update the post_manually value for assignments not specified', () => {
      const assignmentPostPoliciesById = {2301: {postManually: true}}

      postPolicies.setAssignmentPostPolicies({assignmentPostPoliciesById})
      strictEqual(gradebook.getAssignment('2302').post_manually, false)
    })

    test('does not throw an error if given an assignment ID not in the gradebook', () => {
      const assignmentPostPoliciesById = {2399: {postManually: true}}

      postPolicies.setAssignmentPostPolicies({assignmentPostPoliciesById})
      ok('setAssignmentPostPolicies with a nonexistent assignment does not cause an error')
    })

    test('calls updateColumnHeaders on the associated Gradebook object', () => {
      sinon.spy(gradebook, 'updateColumnHeaders')
      postPolicies.setAssignmentPostPolicies({assignmentPostPoliciesById: {}})

      strictEqual(gradebook.updateColumnHeaders.callCount, 1)
      gradebook.updateColumnHeaders.restore()
    })
  })
})
