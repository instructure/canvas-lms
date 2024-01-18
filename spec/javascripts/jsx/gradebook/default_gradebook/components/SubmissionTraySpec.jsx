/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import {mount, shallow} from 'enzyme'

import SubmissionTray from 'ui/features/gradebook/react/default_gradebook/components/SubmissionTray'
import GradeInputDriver from './GradeInput/GradeInputDriver'
import fakeENV from 'helpers/fakeENV'

/* eslint qunit/no-identical-names: 0 */

QUnit.module('SubmissionTray', hooks => {
  let defaultProps
  let clock
  let content
  let wrapper

  hooks.beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    const applicationElement = document.createElement('div')
    applicationElement.id = 'application'
    document.getElementById('fixtures').appendChild(applicationElement)
    clock = sinon.useFakeTimers()

    defaultProps = {
      contentRef(ref) {
        content = ref
      },
      colors: {
        late: '#FEF7E5',
        missing: '#F99',
        excused: '#E5F3FC',
      },
      editedCommentId: null,
      editSubmissionComment() {},
      enterGradesAs: 'points',
      gradingDisabled: false,
      gradingScheme: [
        ['A', 0.9],
        ['B+', 0.85],
        ['B', 0.8],
        ['B-', 0.75],
      ],
      locale: 'en',
      onAnonymousSpeedGraderClick() {},
      onGradeSubmission() {},
      onRequestClose() {},
      onClose() {},
      showSimilarityScore: true,
      submissionUpdating: false,
      isOpen: true,
      courseId: '1',
      currentUserId: '2',
      speedGraderEnabled: true,
      student: {
        id: '27',
        name: 'Jane Doe',
        gradesUrl: 'http://gradeUrl/',
        isConcluded: false,
      },
      submission: {
        assignmentId: '30',
        enteredGrade: '10',
        enteredScore: 10,
        excused: false,
        grade: '7',
        gradedAt: new Date().toISOString(),
        hasPostableComments: false,
        id: '2501',
        late: false,
        missing: false,
        pointsDeducted: 3,
        postedAt: null,
        score: 7,
        secondsLate: 0,
        submissionType: 'online_text_entry',
        userId: '27',
        workflowState: 'graded',
      },
      updateSubmission() {},
      updateSubmissionComment() {},
      assignment: {
        anonymizeStudents: false,
        courseId: '1',
        name: 'Book Report',
        gradingType: 'points',
        htmlUrl: 'http://htmlUrl/',
        id: '30',
        moderatedGrading: false,
        muted: false,
        pointsPossible: 10,
        postManually: false,
        published: true,
        submissionTypes: ['online_text_entry', 'online_upload'],
      },
      isFirstAssignment: false,
      isLastAssignment: false,
      selectNextAssignment() {},
      selectPreviousAssignment() {},
      isFirstStudent: false,
      isLastStudent: false,
      selectNextStudent() {},
      selectPreviousStudent() {},
      submissionCommentsLoaded: true,
      createSubmissionComment() {},
      deleteSubmissionComment() {},
      processing: false,
      setProcessing() {},
      submissionComments: [],
      isInOtherGradingPeriod: false,
      isInClosedGradingPeriod: false,
      isInNoGradingPeriod: false,
      isNotCountedForScore: false,
    }
  })

  hooks.afterEach(() => {
    wrapper.unmount()
    document.getElementById('fixtures').innerHTML = ''
    clock.restore()
    fakeENV.teardown()
  })

  function mountComponent(props) {
    wrapper = mount(<SubmissionTray {...defaultProps} {...props} />)
    clock.tick(50) // wait for Tray to transition open
  }

  function avatarDiv() {
    return document.querySelector('#SubmissionTray__Avatar')
  }

  function studentNameDiv() {
    return document.querySelector('#student-carousel a')
  }

  function carouselButton(label) {
    const $buttons = [...content.querySelectorAll('button')]
    return $buttons.find($button => $button.textContent.trim() === label)
  }

  function submitForStudentButton() {
    return carouselButton('Submit for Student')
  }

  function radioInputGroupDiv() {
    return document.querySelector('[data-testid="SubmissionTray__RadioInputGroup"]')
  }

  function assertElementDisabled($elt, disabled, message) {
    strictEqual($elt.getAttribute('disabled'), disabled ? '' : null, message)
  }

  function speedGraderLink() {
    return document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]')
  }

  function studentGroupRequiredAlert() {
    return [...document.querySelectorAll('div')].find($el =>
      $el.textContent.includes('you must select a student group')
    )
  }

  QUnit.module('Student Carousel', () => {
    function assertStudentButtonsDisabled(disabled) {
      ;['Previous student', 'Next student'].forEach(label => {
        const $button = carouselButton(label)
        const message = `'${label}' button is ${disabled ? '' : 'not '} disabled`
        assertElementDisabled($button, disabled, message)
      })
    }

    test('is disabled when the tray is "processing"', () => {
      mountComponent({processing: true})
      assertStudentButtonsDisabled(true)
    })

    test('is not disabled when the tray is not "processing"', () => {
      mountComponent({processing: false})
      assertStudentButtonsDisabled(false)
    })

    test('is disabled when the submission comments have not loaded', () => {
      mountComponent({submissionCommentsLoaded: false})
      assertStudentButtonsDisabled(true)
    })

    test('is not disabled when the submission comments have loaded', () => {
      mountComponent({submissionCommentsLoaded: true})
      assertStudentButtonsDisabled(false)
    })

    test('is disabled when the submission is updating', () => {
      mountComponent({submissionUpdating: true})
      assertStudentButtonsDisabled(true)
    })

    test('is not disabled when the submission is not updating', () => {
      mountComponent({submissionUpdating: false})
      assertStudentButtonsDisabled(false)
    })
  })

  QUnit.module('Assignment Carousel', () => {
    function assertAssignmentButtonsDisabled(disabled) {
      ;['Previous assignment', 'Next assignment'].forEach(label => {
        const $button = carouselButton(label)
        const message = `'${label}' button is ${disabled ? '' : 'not '} disabled`
        assertElementDisabled($button, disabled, message)
      })
    }

    test('is disabled when the tray is "processing"', () => {
      mountComponent({processing: true})
      assertAssignmentButtonsDisabled(true)
    })

    test('is not disabled when the tray is not "processing"', () => {
      mountComponent({processing: false})
      assertAssignmentButtonsDisabled(false)
    })

    test('is disabled when the submission comments have not loaded', () => {
      mountComponent({submissionCommentsLoaded: false})
      assertAssignmentButtonsDisabled(true)
    })

    test('is not disabled when the submission comments have loaded', () => {
      mountComponent({submissionCommentsLoaded: true})
      assertAssignmentButtonsDisabled(false)
    })

    test('is disabled when the submission is updating', () => {
      mountComponent({submissionUpdating: true})
      assertAssignmentButtonsDisabled(true)
    })

    test('is not disabled when the submission is not updating', () => {
      mountComponent({submissionUpdating: false})
      assertAssignmentButtonsDisabled(false)
    })
  })

  QUnit.module('Submit for Student', () => {
    test('is not displayed when proxySubmissionsAllowed is false', () => {
      mountComponent({proxySubmissionsAllowed: false})
      notOk(submitForStudentButton())
    })

    test('is displayed when proxySubmissionsAllowed is true', () => {
      mountComponent({proxySubmissionsAllowed: true})
      ok(submitForStudentButton())
    })
  })

  test('shows proxy submitter indicator if most recent submission is a proxy', () => {
    const props = {
      submission: {
        assignmentId: '30',
        enteredGrade: '10',
        enteredScore: 10,
        excused: false,
        grade: '7',
        gradedAt: new Date().toISOString(),
        hasPostableComments: false,
        id: '2501',
        late: false,
        missing: false,
        pointsDeducted: 3,
        postedAt: null,
        proxySubmitter: 'Captain America',
        score: 7,
        secondsLate: 0,
        submissionType: 'online_text_entry',
        userId: '27',
        workflowState: 'graded',
      },
    }
    mountComponent(props)
    ok(content.textContent.includes('Submitted by Captain America'))
  })

  test('shows SpeedGrader link if enabled', () => {
    const speedGraderUrl = encodeURI(
      '/courses/1/gradebook/speed_grader?assignment_id=30&student_id=27'
    )
    mountComponent()
    strictEqual(speedGraderLink().getAttribute('href'), speedGraderUrl)
  })

  test('invokes "onAnonymousSpeedGraderClick" when the SpeedGrader link is clicked if the assignment is anonymous', () => {
    const props = {
      assignment: {
        anonymizeStudents: true,
        name: 'Book Report',
        gradingType: 'points',
        htmlUrl: 'http://htmlUrl/',
        published: true,
      },
      onAnonymousSpeedGraderClick: sinon.stub(),
    }
    mountComponent(props)
    speedGraderLink().click()
    strictEqual(props.onAnonymousSpeedGraderClick.callCount, 1)
  })

  test('omits student_id from SpeedGrader link if enabled and assignment has anonymized students', () => {
    mountComponent({assignment: {anonymizeStudents: true}})
    notOk(
      speedGraderLink()
        .getAttribute('href')
        .match(/student_id/)
    )
  })

  test('does not show SpeedGrader link if disabled', () => {
    mountComponent({speedGraderEnabled: false})
    notOk(speedGraderLink())
  })

  QUnit.module('when requireStudentGroupForSpeedGrader is true', requireStudentGroupHooks => {
    requireStudentGroupHooks.beforeEach(() => {
      mountComponent({requireStudentGroupForSpeedGrader: true})
    })

    test('disables the SpeedGrader link', () => {
      strictEqual(speedGraderLink().getAttribute('disabled'), '')
    })

    test('shows an alert indicating a group must be selected', () => {
      ok(studentGroupRequiredAlert())
    })
  })

  test('"Hidden" is displayed when a submission is graded and unposted', () => {
    defaultProps.submission.workflowState = 'graded'
    mountComponent()
    ok(content.textContent.includes('Hidden'))
  })

  test('"Hidden" is displayed when a submission has comments and is unposted', () => {
    defaultProps.submission.hasPostableComments = true
    mountComponent()
    ok(content.textContent.includes('Hidden'))
  })

  test('shows avatar if avatar is not null', () => {
    const avatarUrl = 'http://bob_is_not_a_domain/me.jpg?filter=make_me_pretty'
    const gradesUrl = 'http://gradesUrl/'
    const props = {student: {id: '27', name: 'Bob', avatarUrl, gradesUrl, isConcluded: false}}

    wrapper = shallow(<SubmissionTray {...defaultProps} {...props} />)
    strictEqual(wrapper.find('Avatar').prop('src'), avatarUrl)
  })

  test('shows no avatar if avatar is null', () => {
    mountComponent({
      student: {id: '27', name: 'Joe', gradesUrl: 'http://gradesUrl/', isConcluded: false},
    })
    notOk(avatarDiv())
  })

  test('shows the state of the submission', () => {
    defaultProps.isNotCountedForScore = true
    mountComponent()
    ok(content.textContent.includes('Not calculated in final grade'))
  })

  test('passes along isInOtherGradingPeriod prop to SubmissionStatus', () => {
    defaultProps.isInOtherGradingPeriod = true
    mountComponent()
    ok(content.textContent.includes('This submission is in another grading period'))
  })

  test('passes along isInClosedGradingPeriod prop to SubmissionStatus', () => {
    defaultProps.isInClosedGradingPeriod = true
    mountComponent()
    ok(content.textContent.includes('This submission is in a closed grading period'))
  })

  test('passes along isInNoGradingPeriod prop to SubmissionStatus', () => {
    defaultProps.isInNoGradingPeriod = true
    mountComponent()
    ok(content.textContent.includes('This submission is not in any grading period'))
  })

  test('shows student name', () => {
    mountComponent({
      student: {id: '27', name: 'Sara', gradesUrl: 'http://gradeUrl/', isConcluded: false},
    })
    strictEqual(studentNameDiv().innerText, 'Sara')
  })

  QUnit.module('LatePolicyGrade', () => {
    test('shows the late policy grade when points have been deducted', () => {
      mountComponent()
      ok(content.querySelector('#late-penalty-value'))
    })

    test('uses the submission to show the late policy grade', () => {
      mountComponent()
      const $el = content.querySelector('#late-penalty-value')
      strictEqual($el.textContent, '-3')
    })

    test('does not show the late policy grade when zero points have been deducted', () => {
      mountComponent({
        submission: {
          excused: false,
          id: '2501',
          late: true,
          missing: false,
          pointsDeducted: 0,
          secondsLate: 0,
          assignmentId: '30',
        },
      })
      notOk(content.querySelector('#late-penalty-value'))
    })

    test('does not show the late policy grade when points deducted is null', () => {
      mountComponent({
        submission: {
          excused: false,
          id: '2501',
          late: true,
          missing: false,
          pointsDeducted: null,
          secondsLate: 0,
          assignmentId: '30',
        },
      })
      notOk(content.querySelector('#late-penalty-value'))
    })

    test('receives the "enterGradesAs" given to the Tray', () => {
      mountComponent({enterGradesAs: 'percent'})
      const $el = content.querySelector('#final-grade-value')
      strictEqual($el.textContent, '70%')
    })

    test('receives the "gradingScheme" given to the Tray', () => {
      const gradingScheme = [
        ['A', 0.9],
        ['B+', 0.85],
        ['B', 0.8],
        ['B-', 0.75],
        ['C+', 0.7],
      ]
      mountComponent({enterGradesAs: 'gradingScheme', gradingScheme})
      const $el = content.querySelector('#final-grade-value')
      strictEqual($el.textContent, 'C+')
    })
  })

  test('shows a radio input group', () => {
    mountComponent()
    ok(radioInputGroupDiv())
  })

  test('enables the late policy radio input group when gradingDisabled is false', () => {
    mountComponent({gradingDisabled: false})
    const $inputs = content.querySelectorAll('[name="SubmissionTrayRadioInput"]')
    $inputs.forEach($input => {
      assertElementDisabled($input, false)
    })
  })

  test('disables the late policy radio input group when gradingDisabled is true', () => {
    mountComponent({gradingDisabled: true})
    const $inputs = content.querySelectorAll('[name="SubmissionTrayRadioInput"]')
    $inputs.forEach($input => {
      assertElementDisabled($input, true)
    })
  })

  test('shows assignment carousel', () => {
    mountComponent()
    ok(content.querySelector('#assignment-carousel'))
  })

  test('shows assignment carousel containing given assignment name', () => {
    mountComponent()
    const $el = content.querySelector('#assignment-carousel')
    ok($el.textContent.includes('Book Report'))
  })

  test('shows assignment carousel with no left arrow when isFirstAssignment and isLastAssignment are true', () => {
    defaultProps = {...defaultProps, isFirstAssignment: true, isLastAssignment: true}
    mountComponent()
    strictEqual(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length,
      0
    )
  })

  test('shows assignment carousel with no right arrow when isFirstAssignment and isLastAssignment are true', () => {
    mountComponent({isFirstAssignment: true, isLastAssignment: true})
    strictEqual(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length,
      0
    )
  })

  test('shows assignment carousel with left arrow when isFirstAssignment and isLastAssignment are false', () => {
    mountComponent({isFirstAssignment: false, isLastAssignment: false})
    strictEqual(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length,
      1
    )
  })

  test('shows assignment carousel with right arrow when isFirstAssignment and isLastAssignment are false', () => {
    mountComponent({isFirstAssignment: false, isLastAssignment: false})
    strictEqual(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length,
      1
    )
  })

  test('shows assignment carousel with left arrow when isFirstAssignment is false', () => {
    mountComponent({isFirstAssignment: false, isLastAssignment: true})
    strictEqual(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length,
      1
    )
  })

  test('shows assignment carousel with no right arrow when isFirstAssignment is false', () => {
    mountComponent({isFirstAssignment: false, isLastAssignment: true})
    strictEqual(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length,
      0
    )
  })

  test('shows assignment carousel with right arrow when isLastAssignment is false', () => {
    mountComponent({isFirstAssignment: true, isLastAssignment: false})
    strictEqual(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length,
      1
    )
  })

  test('shows assignment carousel with no left arrow when isLastAssignment is false', () => {
    mountComponent({isFirstAssignment: true, isLastAssignment: false})
    strictEqual(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length,
      0
    )
  })

  test('shows student carousel', () => {
    mountComponent()
    ok(content.querySelector('#student-carousel'))
  })

  test('shows student carousel containing given student name', () => {
    mountComponent()
    const $el = content.querySelector('#student-carousel')
    ok($el.textContent.includes('Jane Doe'))
  })

  test('shows student carousel with no left arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: true,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length,
      0
    )
  })

  test('shows student carousel with no right arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: true,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length,
      0
    )
  })

  test('shows student carousel with left arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length,
      1
    )
  })

  test('shows student carousel with right arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .right-arrow-button-container button').length,
      1
    )
  })

  test('shows student carousel with left arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length,
      1
    )
  })

  test('shows student carousel with no right arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .right-arrow-button-container button').length,
      0
    )
  })

  test('shows student carousel with right arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .right-arrow-button-container button').length,
      1
    )
  })

  test('shows student carousel with no left arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false,
    })
    strictEqual(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length,
      0
    )
  })

  QUnit.module('Grade Input', function () {
    function findGradeInput() {
      return GradeInputDriver.find(content)
    }

    test('receives the "assignment" given to the Tray', function () {
      const assignment = {
        anonymizeStudents: false,
        gradingType: 'points',
        htmlUrl: 'http://htmlUrl/',
        moderatedGrading: false,
        muted: false,
        name: 'Book Report',
        pointsPossible: 10,
        published: true,
      }
      mountComponent({assignment})
      equal(findGradeInput().labelText, 'Grade out of 10')
    })

    test('is disabled when grading is disabled', () => {
      mountComponent({gradingDisabled: true})
      strictEqual(findGradeInput().inputIsDisabled, true)
    })

    test('is not disabled when grading is not disabled', () => {
      mountComponent({gradingDisabled: false})
      strictEqual(findGradeInput().inputIsDisabled, false)
    })

    test('receives the "onGradeSubmission" callback given to the Tray', () => {
      const onGradeSubmission = sinon.stub()
      mountComponent({onGradeSubmission})
      const gradeInput = findGradeInput()
      gradeInput.inputValue('EX')
      gradeInput.blurInput()
      strictEqual(onGradeSubmission.callCount, 1)
    })

    test('receives the "submission" given to the Tray', () => {
      mountComponent()
      strictEqual(findGradeInput().value, '10')
    })

    test('receives the "submissionUpdating" given to the Tray', () => {
      mountComponent({submissionUpdating: true})
      strictEqual(findGradeInput().isReadOnly, true)
    })

    test('receives the "enterGradesAs" given to the Tray', () => {
      mountComponent({enterGradesAs: 'percent'})
      equal(findGradeInput().labelText, 'Grade out of 100%')
    })

    test('receives the "gradingScheme" given to the Tray', () => {
      const gradingScheme = [
        ['A', 0.9],
        ['B+', 0.85],
        ['B', 0.8],
        ['B-', 0.75],
        ['C+', 0.7],
      ]
      mountComponent({enterGradesAs: 'gradingScheme', gradingScheme})
      equal(findGradeInput().labelText, 'Letter Grade')
    })

    test('receives the "pendingGradeInfo" given to the Tray', () => {
      const pendingGradeInfo = {
        excused: false,
        grade: '15',
        valid: true,
      }
      mountComponent({pendingGradeInfo})
      strictEqual(findGradeInput().value, '15')
    })
  })

  QUnit.module('Similarity Score', function (similarityHooks) {
    let submission

    similarityHooks.beforeEach(function () {
      submission = defaultProps.submission
      submission.turnitin_data = {submission_2501: {status: 'scored', similarity_score: 55}}
    })

    test('does not render if students are anonymized', function () {
      defaultProps.assignment.anonymizeStudents = true
      mountComponent()
      notOk(content.textContent.includes('55.0% similarity score'))
    })

    test('does not render if the submission has no originality data', function () {
      submission.turnitin_data = {}
      mountComponent()
      notOk(content.textContent.includes('55.0% similarity score'))
    })

    test('does not render if the showSimilarityScore prop is false', function () {
      mountComponent({showSimilarityScore: false})
      notOk(content.textContent.includes('55.0% similarity score'))
    })

    QUnit.module('when originality data exists and students are not anonymized', function () {
      test('renders the similarity score with data from the submission', function () {
        mountComponent()
        ok(content.textContent.includes('55.0% similarity score'))
      })

      test('includes a link to the originality report for the submission', function () {
        mountComponent()
        ok(content.querySelector('a[href$="/submissions/27/turnitin/submission_2501"]'))
      })

      test('includes a message when the submission is a file upload submission with multiple reports', function () {
        submission.submissionType = 'online_upload'
        submission.attachments = [{id: '1001'}, {id: '1002'}]
        submission.turnitinData = {
          attachment_1001: {status: 'pending'},
          attachment_1002: {status: 'error'},
        }
        mountComponent()
        ok(
          content.textContent.includes(
            'This submission has plagiarism data for multiple attachments.'
          )
        )
      })

      test('does not include a "multiple reports" when the submission only has one report', function () {
        mountComponent()
        notOk(
          content.textContent.includes(
            'This submission has plagiarism data for multiple attachments.'
          )
        )
      })
    })
  })

  test('renders the new comment form if the editedCommentId is null', function () {
    mountComponent()
    ok(content.querySelector('textarea[placeholder="Leave a comment"]'))
  })

  test('renders new comment form if assignment is not muted', () => {
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: true,
      muted: false,
      name: 'foo',
      published: false,
    }
    mountComponent({assignment})
    ok(content.querySelector('textarea[placeholder="Leave a comment"]'))
  })

  test('renders new comment form if assignment is muted and not anonymous or moderated', () => {
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: false,
      muted: true,
      name: 'foo',
      published: false,
    }
    mountComponent({assignment})
    ok(content.querySelector('textarea[placeholder="Leave a comment"]'))
  })

  test('does not render new comment form if assignment has anonymized students', () => {
    const assignment = {
      anonymizeStudents: true,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: false,
      muted: true,
      name: 'foo',
      published: false,
    }
    mountComponent({assignment})
    notOk(content.querySelector('textarea[placeholder="Leave a comment"]'))
  })

  test('does not render new comment form if assignment is muted and moderated', () => {
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: true,
      muted: true,
      name: 'foo',
      published: false,
    }
    mountComponent({assignment})
    notOk(content.querySelector('textarea[placeholder="Leave a comment"]'))
  })

  test('does not render the new comment form if the editedCommentId is not null', () => {
    mountComponent({editedCommentId: '5'})
    notOk(content.querySelector('textarea[placeholder="Leave a comment"]'))
  })

  test('cancelCommenting calls editSubmissionComment', () => {
    const editSubmissionComment = sinon.stub()
    mountComponent({editedCommentId: '5', editSubmissionComment})
    wrapper.instance().cancelCommenting()
    strictEqual(editSubmissionComment.callCount, 1)
  })

  test('cancelCommenting sets the edited submission comment id to null', () => {
    const editSubmissionComment = sinon.stub()
    mountComponent({editedCommentId: '5', editSubmissionComment})
    wrapper.instance().cancelCommenting()
    const editedCommentId = editSubmissionComment.firstCall.args[0]
    strictEqual(editedCommentId, null)
  })
})
