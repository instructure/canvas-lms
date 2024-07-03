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
import {fireEvent, render} from '@testing-library/react'

import SubmissionTray from '../SubmissionTray'

// Delete the GradeInputDriver in spec/javascripts/jsx/gradebook
// when stuff using it over there is migrated
import GradeInputDriver from './GradeInputDriver'

describe('SubmissionTray', () => {
  let props: any
  let content: any
  let reactRef: any

  beforeEach(() => {
    window.ENV.GRADEBOOK_OPTIONS = {assignment_missing_shortcut: true}
    props = {
      contentRef(ref: any) {
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

  function mountComponent(extra_props?: any) {
    reactRef = React.createRef()
    render(<SubmissionTray {...props} {...extra_props} ref={reactRef} />)
  }

  function avatarDiv() {
    return document.querySelector('#SubmissionTray__Avatar')
  }

  function studentNameDiv() {
    return document.querySelector('#student-carousel a')
  }

  function carouselButton(label: string) {
    const $buttons = [...content.querySelectorAll('button')]
    return $buttons.find($button => $button.textContent.trim() === label)
  }

  function submitForStudentButton() {
    return carouselButton('Submit for Student')
  }

  function radioInputGroupDiv() {
    return document.querySelector('[data-testid="SubmissionTray__RadioInputGroup"]')
  }

  function assertElementDisabled($elt: any, disabled: boolean) {
    expect($elt.getAttribute('disabled')).toEqual(disabled ? '' : null)
  }

  function speedGraderLink() {
    return document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]')
  }

  function studentGroupRequiredAlert() {
    return [...document.querySelectorAll('div')].find($el =>
      $el.textContent?.includes('you must select a student group')
    )
  }

  describe('Student Carousel', () => {
    function assertStudentButtonsDisabled(disabled: boolean) {
      const buttons = ['Previous student', 'Next student']
      buttons.forEach(label => {
        const $button = carouselButton(label)
        assertElementDisabled($button, disabled)
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

  describe('Assignment Carousel', () => {
    function assertAssignmentButtonsDisabled(disabled: boolean) {
      const buttons = ['Previous assignment', 'Next assignment']
      buttons.forEach(label => {
        const $button = carouselButton(label)
        assertElementDisabled($button, disabled)
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

  describe('Submit for Student', () => {
    test('is not displayed when proxySubmissionsAllowed is false', () => {
      mountComponent({proxySubmissionsAllowed: false})
      expect(submitForStudentButton()).toBe(undefined)
    })

    test('is displayed when proxySubmissionsAllowed is true', () => {
      mountComponent({proxySubmissionsAllowed: true})
      expect(submitForStudentButton()).toBeInTheDocument()
    })
  })

  test('shows proxy submitter indicator if most recent submission is a proxy', () => {
    const extra_props = {
      submission: {
        assignmentId: '30',
        enteredGrade: '10',
        enteredScore: 10,
        excused: false,
        grade: '7',
        gradedAt: new Date().toISOString(),
        submittedAt: new Date().toISOString(),
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
    mountComponent(extra_props)
    expect(content.textContent).toContain('Submitted by Captain America')
  })

  test('shows SpeedGrader link if enabled', () => {
    const speedGraderUrl = encodeURI(
      '/courses/1/gradebook/speed_grader?assignment_id=30&student_id=27'
    )
    mountComponent()
    expect(speedGraderLink()?.getAttribute('href')).toEqual(speedGraderUrl)
  })

  test('invokes "onAnonymousSpeedGraderClick" when the SpeedGrader link is clicked if the assignment is anonymous', () => {
    props.assignment.anonymizeStudents = true
    props.assignment.name = 'Book Report'
    props.assignment.gradingType = 'points'
    props.assignment.htmlUrl = 'http://htmlUrl/'
    props.assignment.published = true
    props.onAnonymousSpeedGraderClick = jest.fn()

    mountComponent()
    fireEvent.click(speedGraderLink()!)
    expect(props.onAnonymousSpeedGraderClick).toHaveBeenCalledTimes(1)
  })

  test('omits student_id from SpeedGrader link if enabled and assignment has anonymized students', () => {
    props.assignment.anonymizeStudents = true
    mountComponent()
    expect(
      speedGraderLink()
        ?.getAttribute('href')
        ?.match(/student_id/)
    ).toBe(null)
  })

  test('does not show SpeedGrader link if disabled', () => {
    mountComponent({speedGraderEnabled: false})
    expect(speedGraderLink()).toBe(null)
  })

  describe('when requireStudentGroupForSpeedGrader is true', () => {
    beforeEach(() => {
      mountComponent({requireStudentGroupForSpeedGrader: true})
    })

    test('disables the SpeedGrader link', () => {
      expect(speedGraderLink()?.getAttribute('disabled')).toEqual('')
    })

    test('shows an alert indicating a group must be selected', () => {
      expect(studentGroupRequiredAlert()).toBeInTheDocument()
    })
  })

  test('"Hidden" is displayed when a submission is graded and unposted', () => {
    props.submission.workflowState = 'graded'
    mountComponent()
    expect(content.textContent).toContain('Hidden')
  })

  test('"Hidden" is displayed when a submission has comments and is unposted', () => {
    props.submission.hasPostableComments = true
    mountComponent()
    expect(content.textContent).toContain('Hidden')
  })

  test('shows avatar if avatar is not null', () => {
    const avatarUrl = 'http://bob_is_not_a_domain/me.jpg?filter=make_me_pretty'
    const gradesUrl = 'http://gradesUrl/'
    props.student = {id: '27', name: 'Bob', avatarUrl, gradesUrl, isConcluded: false}
    mountComponent()
    expect(content.querySelector('img').getAttribute('src')).toEqual(avatarUrl)
  })

  test('shows no avatar if avatar is null', () => {
    mountComponent({
      student: {id: '27', name: 'Joe', gradesUrl: 'http://gradesUrl/', isConcluded: false},
    })
    expect(avatarDiv()).toBe(null)
  })

  test('shows the state of the submission', () => {
    props.isNotCountedForScore = true
    mountComponent()
    expect(content.textContent).toContain('Not calculated in final grade')
  })

  test('passes along isInOtherGradingPeriod prop to SubmissionStatus', () => {
    props.isInOtherGradingPeriod = true
    mountComponent()
    expect(content.textContent).toContain('This submission is in another grading period')
  })

  test('passes along isInClosedGradingPeriod prop to SubmissionStatus', () => {
    props.isInClosedGradingPeriod = true
    mountComponent()
    expect(content.textContent).toContain('This submission is in a closed grading period')
  })

  test('passes along isInNoGradingPeriod prop to SubmissionStatus', () => {
    props.isInNoGradingPeriod = true
    mountComponent()
    expect(content.textContent).toContain('This submission is not in any grading period')
  })

  test('shows student name', () => {
    mountComponent({
      student: {id: '27', name: 'Sara', gradesUrl: 'http://gradeUrl/', isConcluded: false},
    })
    expect(studentNameDiv()?.textContent).toEqual('Sara')
  })

  describe('LatePolicyGrade', () => {
    test('shows the late policy grade when points have been deducted', () => {
      mountComponent()
      expect(content.querySelector('#late-penalty-value')).toBeInTheDocument()
    })

    test('uses the submission to show the late policy grade', () => {
      mountComponent()
      const $el = content.querySelector('#late-penalty-value')
      expect($el.textContent).toEqual('-3')
    })

    test('does not show the late policy grade when zero points have been deducted', () => {
      props.submission.pointsDeducted = 0
      mountComponent()
      expect(content.querySelector('#late-penalty-value')).toBe(null)
    })

    test('does not show the late policy grade when points deducted is null', () => {
      props.submission.pointsDeducted = null
      mountComponent()
      expect(content.querySelector('#late-penalty-value')).toBe(null)
    })

    test('receives the "enterGradesAs" given to the Tray', () => {
      mountComponent({enterGradesAs: 'percent'})
      const $el = content.querySelector('#final-grade-value')
      expect($el.textContent).toEqual('70%')
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
      expect($el.textContent).toEqual('C+')
    })
  })

  test('shows a radio input group', () => {
    mountComponent()
    expect(radioInputGroupDiv()).toBeInTheDocument()
  })

  test('enables the late policy radio input group when gradingDisabled is false', () => {
    mountComponent({gradingDisabled: false})
    const $inputs = content.querySelectorAll('[name="SubmissionTrayRadioInput"]')
    $inputs.forEach(($input: any) => {
      assertElementDisabled($input, false)
    })
  })

  test('disables the late policy radio input group when gradingDisabled is true', () => {
    mountComponent({gradingDisabled: true})
    const $inputs = content.querySelectorAll('[name="SubmissionTrayRadioInput"]')
    $inputs.forEach(($input: any) => {
      assertElementDisabled($input, true)
    })
  })

  test('shows assignment carousel', () => {
    mountComponent()
    expect(content.querySelector('#assignment-carousel')).toBeInTheDocument()
  })

  test('shows assignment carousel containing given assignment name', () => {
    mountComponent()
    const $el = content.querySelector('#assignment-carousel')
    expect($el.textContent).toContain('Book Report')
  })

  test('shows assignment carousel with no left arrow when isFirstAssignment and isLastAssignment are true', () => {
    props.isFirstAssignment = true
    props.isLastAssignment = true
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length
    ).toBe(0)
  })

  test('shows assignment carousel with no right arrow when isFirstAssignment and isLastAssignment are true', () => {
    props.isFirstAssignment = true
    props.isLastAssignment = true
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length
    ).toBe(0)
  })

  test('shows assignment carousel with left arrow when isFirstAssignment and isLastAssignment are false', () => {
    props.isFirstAssignment = false
    props.isLastAssignment = false
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows assignment carousel with right arrow when isFirstAssignment and isLastAssignment are false', () => {
    props.isFirstAssignment = false
    props.isLastAssignment = false
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows assignment carousel with left arrow when isFirstAssignment is false', () => {
    props.isFirstAssignment = false
    props.isLastAssignment = true
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows assignment carousel with no right arrow when isFirstAssignment is false', () => {
    props.isFirstAssignment = false
    props.isLastAssignment = true
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length
    ).toBe(0)
  })

  test('shows assignment carousel with right arrow when isLastAssignment is false', () => {
    props.isFirstAssignment = true
    props.isLastAssignment = false
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows assignment carousel with no left arrow when isLastAssignment is false', () => {
    props.isFirstAssignment = true
    props.isLastAssignment = false
    mountComponent()
    expect(
      content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length
    ).toBe(0)
  })

  test('shows student carousel', () => {
    mountComponent()
    expect(content.querySelector('#student-carousel')).toBeInTheDocument()
  })

  test('shows student carousel containing given student name', () => {
    mountComponent()
    const $el = content.querySelector('#student-carousel')
    expect($el.textContent).toContain('Jane Doe')
  })

  test('shows student carousel with no left arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: true,
    })
    expect(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length
    ).toBe(0)
  })

  test('shows student carousel with no right arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: true,
    })
    expect(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length
    ).toBe(0)
  })

  test('shows student carousel with left arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false,
    })
    expect(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows student carousel with right arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false,
    })
    expect(
      content.querySelectorAll('#student-carousel .right-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows student carousel with left arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true,
    })
    expect(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows student carousel with no right arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true,
    })
    expect(
      content.querySelectorAll('#student-carousel .right-arrow-button-container button').length
    ).toBe(0)
  })

  test('shows student carousel with right arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false,
    })
    expect(
      content.querySelectorAll('#student-carousel .right-arrow-button-container button').length
    ).toBe(1)
  })

  test('shows student carousel with no left arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false,
    })
    expect(
      content.querySelectorAll('#student-carousel .left-arrow-button-container button').length
    ).toBe(0)
  })

  describe('Grade Input', function () {
    function findGradeInput() {
      return GradeInputDriver.find(content)
    }

    test('receives the "assignment" given to the Tray', function () {
      props.assignment.published = true
      mountComponent()
      expect(findGradeInput()?.labelText).toEqual('Grade out of 10')
    })

    test('is disabled when grading is disabled', () => {
      mountComponent({gradingDisabled: true})
      expect(findGradeInput()?.inputIsDisabled).toBe(true)
    })

    test('is not disabled when grading is not disabled', () => {
      mountComponent({gradingDisabled: false})
      expect(findGradeInput()?.inputIsDisabled).toBe(false)
    })

    test('receives the "onGradeSubmission" callback given to the Tray', async () => {
      const onGradeSubmission = jest.fn()
      mountComponent({onGradeSubmission})
      const gradeInput = findGradeInput()
      await gradeInput?.inputValueAndBlur('EX')
      expect(onGradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('receives the "submission" given to the Tray', () => {
      mountComponent()
      expect(findGradeInput()?.value).toEqual('10')
    })

    test('receives the "submissionUpdating" given to the Tray', () => {
      mountComponent({submissionUpdating: true})
      expect(findGradeInput()?.isReadOnly).toBe(true)
    })

    test('receives the "enterGradesAs" given to the Tray', () => {
      mountComponent({enterGradesAs: 'percent'})
      expect(findGradeInput()?.labelText).toEqual('Grade out of 100%')
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
      expect(findGradeInput()?.labelText).toEqual('Letter Grade')
    })

    test('receives the "pendingGradeInfo" given to the Tray', () => {
      const pendingGradeInfo = {
        excused: false,
        grade: '15',
        valid: true,
      }
      mountComponent({pendingGradeInfo})
      expect(findGradeInput()?.value).toEqual('15')
    })
  })

  describe('Similarity Score', function () {
    beforeEach(function () {
      props.submission.turnitin_data = {submission_2501: {status: 'scored', similarity_score: 55}}
    })

    test('does not render if students are anonymized', function () {
      props.assignment.anonymizeStudents = true
      mountComponent()
      expect(content.textContent).not.toContain('55.0% similarity score')
    })

    test('does not render if the submission has no originality data', function () {
      props.submission.turnitin_data = {}
      mountComponent()
      expect(content.textContent).not.toContain('55.0% similarity score')
    })

    test('does not render if the showSimilarityScore prop is false', function () {
      mountComponent({showSimilarityScore: false})
      expect(content.textContent).not.toContain('55.0% similarity score')
    })

    describe('when originality data exists and students are not anonymized', function () {
      test('renders the similarity score with data from the submission', function () {
        mountComponent()
        expect(content.textContent).toContain('55.0% similarity score')
      })

      test('includes a link to the originality report for the submission', function () {
        mountComponent()
        expect(
          content.querySelector('a[href$="/submissions/27/turnitin/submission_2501"]')
        ).toBeInTheDocument()
      })

      test('includes a message when the submission is a file upload submission with multiple reports', function () {
        props.submission.submissionType = 'online_upload'
        props.submission.attachments = [{id: '1001'}, {id: '1002'}]
        props.submission.turnitinData = {
          attachment_1001: {status: 'pending'},
          attachment_1002: {status: 'error'},
        }
        mountComponent()
        expect(content.textContent).toContain(
          'This submission has plagiarism data for multiple attachments.'
        )
      })

      test('does not include a "multiple reports" when the submission only has one report', function () {
        mountComponent()
        expect(content.textContent).not.toContain(
          'This submission has plagiarism data for multiple attachments.'
        )
      })
    })
  })

  test('renders the new comment form if the editedCommentId is null', function () {
    mountComponent()
    expect(content.querySelector('textarea[placeholder="Leave a comment"]')).toBeInTheDocument()
  })

  test('renders new comment form if assignment is not muted', () => {
    props.assignment.muted = false
    mountComponent()
    expect(content.querySelector('textarea[placeholder="Leave a comment"]')).toBeInTheDocument()
  })

  test('renders new comment form if assignment is muted and not anonymous or moderated', () => {
    props.assignment.muted = true
    props.assignment.anonymizeStudents = false
    props.assignment.moderatedGrading = false
    mountComponent()
    expect(content.querySelector('textarea[placeholder="Leave a comment"]')).toBeInTheDocument()
  })

  test('does not render new comment form if assignment has anonymized students', () => {
    props.assignment.anonymizeStudents = true
    mountComponent()
    expect(content.querySelector('textarea[placeholder="Leave a comment"]')).toBe(null)
  })

  test('does not render new comment form if assignment is muted and moderated', () => {
    props.assignment.muted = true
    props.assignment.moderatedGrading = true
    mountComponent()
    expect(content.querySelector('textarea[placeholder="Leave a comment"]')).toBe(null)
  })

  test('does not render the new comment form if the editedCommentId is not null', () => {
    mountComponent({editedCommentId: '5'})
    expect(content.querySelector('textarea[placeholder="Leave a comment"]')).toBe(null)
  })

  test('cancelCommenting calls editSubmissionComment', () => {
    const editSubmissionComment = jest.fn()
    mountComponent({editedCommentId: '5', editSubmissionComment})
    reactRef.current.cancelCommenting()
    expect(editSubmissionComment).toHaveBeenCalledTimes(1)
  })

  test('cancelCommenting sets the edited submission comment id to null', () => {
    const editSubmissionComment = jest.fn()
    mountComponent({editedCommentId: '5', editSubmissionComment})
    reactRef.current.cancelCommenting()
    expect(editSubmissionComment).toHaveBeenCalledWith(null)
  })
})
