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

import {screen, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom'
import $ from 'jquery'
import {createGradebook} from './GradebookSpecHelper'
import GradebookApi from '../apis/GradebookApi'
import ReactDOM from 'react-dom'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {calculateCheckpointStates} from '../components/SubmissionTray.tsx'

// Mock global $ for flashError usage
global.$ = $

const defaultGradingScheme = [
  ['A', 0.9],
  ['B', 0.8],
  ['C', 0.7],
  ['D', 0.6],
  ['F', 0],
]

const server = setupServer()

describe('Gradebook#renderSubmissionTray', () => {
  let gradebook
  let submissionStateMapStub

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    jest.clearAllMocks()

    global.ENV = {
      GRADEBOOK_OPTIONS: {
        proxy_submissions_allowed: false,
        custom_grade_statuses: [],
      },
    }

    gradebook = createGradebook()

    submissionStateMapStub = jest.spyOn(gradebook.submissionStateMap, 'getSubmissionState')

    gradebook.gradebookGrid = {
      gridSupport: {
        state: {
          getActiveLocation: () => ({cell: 'grade_1101_2301'}),
        },
        helper: {
          commitCurrentEdit: jest.fn(),
          focus: jest.fn(),
          beginEdit: jest.fn(),
        },
        grid: {
          getColumns: () => [
            {
              id: 'grade_1101_2301',
              assignmentId: '2301',
            },
          ],
        },
      },
      grid: {
        getActiveCell: () => ({row: 0}),
      },
    }

    gradebook.setAssignments({
      2301: {
        id: '2301',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: 'http://assignmentUrl',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry'],
        anonymize_students: false,
        post_manually: false,
      },
    })
    gradebook.setAssignmentGroups({9000: {group_weight: 100}})
    gradebook.options.course_settings = {
      filter_speed_grader_by_student_group: true,
    }

    gradebook.gridData = {
      rows: [{id: '1101'}],
    }

    gradebook.students = {
      1101: {
        id: '1101',
        name: 'Test Student',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://gradesUrl/'}}],
        assignment_2301: {
          assignment_id: '2301',
          id: '2301',
          user_id: '1101',
          grade: 'B',
          score: 8.5,
          excused: false,
          late_policy_status: null,
          seconds_late: 0,
          workflow_state: 'submitted',
        },
      },
    }

    gradebook.setSubmissionTrayState(false)

    const submission = gradebook.getSubmission('1101', '2301')
    jest
      .spyOn(gradebook, 'updateSubmissionAndRenderSubmissionTray')
      .mockResolvedValue({data: {all_submissions: [submission]}})

    jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
    jest.spyOn(gradebook, 'updateRowAndRenderSubmissionTray').mockImplementation(() => {})
  })

  afterEach(() => {
    delete global.ENV
    delete global.$
  })

  describe('Gradebook#renderSubmissionTray - QUnit -> Jest conversions', () => {
    it('calls getSubmissionTrayProps with the student', async () => {
      const student = gradebook.student('1101')
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(student)
      expect(gradebook.renderSubmissionTray).toHaveBeenCalledWith(student)
    })

    it('on success the correct updated submission data is returned', async () => {
      const submission = gradebook.getSubmission('1101', '2301')
      const updateResult = await gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      expect(updateResult.data.all_submissions).toEqual([submission])
    })

    it('sets the tray state to open if it was closed', () => {
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      expect(gradebook.getSubmissionTrayState()).toEqual({
        open: true,
        studentId: '1101',
        assignmentId: '2301',
        commentsLoaded: false,
        comments: [],
        commentsUpdating: false,
        editedCommentId: null,
      })
    })

    it('sets the tray state to closed if it was open', () => {
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.closeSubmissionTray()
      expect(gradebook.getSubmissionTrayState().open).toBe(false)
      expect(gradebook.updateRowAndRenderSubmissionTray).toHaveBeenCalledWith('1101')
    })
  })

  describe('Gradebook#getSubmissionTrayProps - Grading Period States', () => {
    describe('isInOtherGradingPeriod', () => {
      it('isInOtherGradingPeriod is true when the SubmissionStateMap returns true', () => {
        submissionStateMapStub.mockReturnValue({inOtherGradingPeriod: true})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInOtherGradingPeriod).toBe(true)
      })

      it('isInOtherGradingPeriod is false when the SubmissionStateMap returns false', () => {
        submissionStateMapStub.mockReturnValue({inOtherGradingPeriod: false})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInOtherGradingPeriod).toBe(false)
      })

      it('isInOtherGradingPeriod is false when the SubmissionStateMap returns undefined', () => {
        submissionStateMapStub.mockReturnValue({})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInOtherGradingPeriod).toBe(false)
      })
    })

    describe('isInClosedGradingPeriod', () => {
      it('isInClosedGradingPeriod is true when the SubmissionStateMap returns true', () => {
        submissionStateMapStub.mockReturnValue({inClosedGradingPeriod: true})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInClosedGradingPeriod).toBe(true)
      })

      it('isInClosedGradingPeriod is false when the SubmissionStateMap returns false', () => {
        submissionStateMapStub.mockReturnValue({inClosedGradingPeriod: false})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInClosedGradingPeriod).toBe(false)
      })

      it('isInClosedGradingPeriod is false when the SubmissionStateMap returns undefined', () => {
        submissionStateMapStub.mockReturnValue({})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInClosedGradingPeriod).toBe(false)
      })
    })

    describe('isInNoGradingPeriod', () => {
      it('isInNoGradingPeriod is true when the SubmissionStateMap returns true', () => {
        submissionStateMapStub.mockReturnValue({inNoGradingPeriod: true})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInNoGradingPeriod).toBe(true)
      })

      it('isInNoGradingPeriod is false when the SubmissionStateMap returns false', () => {
        submissionStateMapStub.mockReturnValue({inNoGradingPeriod: false})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInNoGradingPeriod).toBe(false)
      })

      it('isInNoGradingPeriod is false when the SubmissionStateMap returns undefined', () => {
        submissionStateMapStub.mockReturnValue({})
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isInNoGradingPeriod).toBe(false)
      })
    })
  })

  describe('Gradebook#getSubmissionTrayProps - Grading Scheme', () => {
    it('gradingScheme is the grading scheme for the assignment', () => {
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.gradingScheme).toEqual(defaultGradingScheme)
    })

    it('enterGradesAs is the "enter grades as" setting for the assignment', () => {
      const getEnterGradesAsSettingSpy = jest.spyOn(gradebook, 'getEnterGradesAsSetting')
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(getEnterGradesAsSettingSpy).toHaveBeenCalledWith('2301')
      expect(props.enterGradesAs).toBe('points')
      getEnterGradesAsSettingSpy.mockRestore()
    })
  })

  describe('Gradebook#getSubmissionTrayProps - isNotCountedForScore', () => {
    it('sets isNotCountedForScore to false when the assignment is counted toward final grade', () => {
      gradebook.assignments[2301].omit_from_final_grade = false
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.isNotCountedForScore).toBe(false)
    })

    it('sets isNotCountedForScore to true when the assignment is not counted toward final grade', () => {
      gradebook.assignments[2301].omit_from_final_grade = true
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.isNotCountedForScore).toBe(true)
    })

    it('sets isNotCountedForScore to false when the assignment group weight is not zero', () => {
      gradebook.assignmentGroups[9000].group_weight = 100
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.isNotCountedForScore).toBe(false)
    })

    describe('when weighting scheme is "percent"', () => {
      beforeEach(() => {
        gradebook.options.group_weighting_scheme = 'percent'
      })

      it('sets isNotCountedForScore to true when group weight is zero and weighting scheme is percent', () => {
        gradebook.assignmentGroups[9000].group_weight = 0
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isNotCountedForScore).toBe(true)
      })

      it('sets isNotCountedForScore to false when group weight is not zero and weighting scheme is percent', () => {
        gradebook.assignmentGroups[9000].group_weight = 100
        gradebook.setSubmissionTrayState(true, '1101', '2301')
        const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
        expect(props.isNotCountedForScore).toBe(false)
      })
    })

    it('sets isNotCountedForScore to false when group weight is zero and weighting scheme is not percent', () => {
      gradebook.assignmentGroups[9000].group_weight = 0
      gradebook.options.group_weighting_scheme = 'equals'
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.isNotCountedForScore).toBe(false)
    })
  })

  describe('Gradebook#getSubmissionTrayProps - pendingGradeInfo', () => {
    it('sets pendingGradeInfo when a pending grade exists for the current student/assignment', () => {
      const pendingGradeInfo = {
        enteredAs: null,
        excused: false,
        grade: null,
        score: null,
        valid: true,
      }
      const submission = {assignmentId: '2301', userId: '1101'}

      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      gradebook.setSubmissionTrayState(true, '1101', '2301')

      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.pendingGradeInfo).toEqual({
        ...pendingGradeInfo,
        assignmentId: '2301',
        userId: '1101',
      })
    })

    it('sets pendingGradeInfo to null when no pending grade exists for the current student/assignment', () => {
      const pendingGradeInfo = {
        enteredAs: null,
        excused: false,
        grade: null,
        score: null,
        valid: true,
      }
      const submission = {assignmentId: '2302', userId: '1101'}

      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      gradebook.setSubmissionTrayState(true, '1101', '2301')

      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.pendingGradeInfo).toBeNull()
    })
  })

  describe('Gradebook#getSubmissionTrayProps - gradingDisabled', () => {
    it('gradingDisabled is true when the submission state is locked', () => {
      submissionStateMapStub.mockReturnValue({locked: true})
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.gradingDisabled).toBe(true)
    })

    it('gradingDisabled is false when the submission state is not locked', () => {
      submissionStateMapStub.mockReturnValue({locked: false})
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.gradingDisabled).toBe(false)
    })

    it('gradingDisabled is false when the submission state is undefined', () => {
      submissionStateMapStub.mockReturnValue(undefined)
      gradebook.student('1101').isConcluded = false
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.gradingDisabled).toBe(false)
    })

    it('gradingDisabled is true when the student enrollment is concluded', () => {
      submissionStateMapStub.mockReturnValue({locked: false})
      gradebook.student('1101').isConcluded = true
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.gradingDisabled).toBe(true)
    })

    it('gradingDisabled is false when the student enrollment is not concluded', () => {
      submissionStateMapStub.mockReturnValue({locked: false})
      gradebook.student('1101').isConcluded = false
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.gradingDisabled).toBe(false)
    })
  })

  describe('Gradebook#getSubmissionTrayProps - onGradeSubmission', () => {
    it('onGradeSubmission is the Gradebook "gradeSubmission" method', () => {
      submissionStateMapStub.mockReturnValue({locked: false})
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.onGradeSubmission).toBe(gradebook.gradeSubmission)
    })
  })

  describe('Gradebook#getSubmissionTrayProps - student properties', () => {
    it('student has valid gradesUrl', () => {
      submissionStateMapStub.mockReturnValue({locked: false})
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.student.gradesUrl).toBe('http://gradesUrl/#tab-assignments')
    })

    it('student has html decoded name', () => {
      submissionStateMapStub.mockReturnValue({locked: false})
      gradebook.students[1101].name = 'Test&#x27; Student'
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.student.name).toBe("Test' Student")
    })

    it('student has isConcluded property', () => {
      submissionStateMapStub.mockReturnValue({locked: false})
      const student = gradebook.student('1101')
      student.isConcluded = true
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(student)
      expect(props.student.isConcluded).toBe(true)
    })
  })

  describe('Gradebook#getSubmissionTrayProps - requireStudentGroupForSpeedGrader', () => {
    beforeEach(() => {
      const studentGroups = [
        {
          groups: [
            {id: '1', name: 'First Group Set 1'},
            {id: '2', name: 'First Group Set 2'},
          ],
          id: '1',
          name: 'First Group Set',
        },
        {
          groups: [
            {id: '3', name: 'Second Group Set 1'},
            {id: '4', name: 'Second Group Set 2'},
          ],
          id: '2',
          name: 'Second Group Set',
        },
      ]
      gradebook.setStudentGroups(studentGroups)
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.options.course_settings = {
        filter_speed_grader_by_student_group: true,
      }
    })

    it('is true when the current assignment is not a group assignment and no group is selected', () => {
      gradebook.options.course_settings.filter_speed_grader_by_student_group = true
      gradebook.setFilterRowsBySetting('studentGroupId', null)
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.requireStudentGroupForSpeedGrader).toBe(true)
    })

    it('is true when the current assignment is a group assignment and grades students individually, with no group selected', () => {
      gradebook.options.course_settings.filter_speed_grader_by_student_group = true
      gradebook.setFilterRowsBySetting('studentGroupId', null)
      gradebook.assignments[2301].group_category_id = '1'
      gradebook.assignments[2301].grade_group_students_individually = true
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.requireStudentGroupForSpeedGrader).toBe(true)
    })

    it('is false when the current assignment is a group assignment but does not grade individually', () => {
      gradebook.options.course_settings.filter_speed_grader_by_student_group = true
      gradebook.setFilterRowsBySetting('studentGroupId', null)
      gradebook.assignments[2301].group_category_id = '1'
      gradebook.assignments[2301].grade_group_students_individually = false
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.requireStudentGroupForSpeedGrader).toBe(false)
    })

    it('is false when a student group is selected', () => {
      gradebook.options.course_settings.filter_speed_grader_by_student_group = true
      gradebook.setFilterRowsBySetting('studentGroupId', '4')
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.requireStudentGroupForSpeedGrader).toBe(false)
    })

    it('is false when filter_speed_grader_by_student_group is not enabled', () => {
      gradebook.options.course_settings.filter_speed_grader_by_student_group = false
      gradebook.setFilterRowsBySetting('studentGroupId', null)
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      expect(props.requireStudentGroupForSpeedGrader).toBe(false)
    })
  })

  describe('Gradebook#updateRowAndRenderSubmissionTray', () => {
    beforeEach(() => {
      gradebook = createGradebook()
      jest.spyOn(gradebook, 'updateRowCellsForStudentIds').mockImplementation(() => {})
      jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
    })

    it('unloads comments for the submission', () => {
      jest.spyOn(gradebook, 'unloadSubmissionComments').mockImplementation(() => {})
      gradebook.updateRowAndRenderSubmissionTray('1')
      expect(gradebook.unloadSubmissionComments).toHaveBeenCalledTimes(1)
    })

    it('updates the row cell for the given student id', () => {
      gradebook.updateRowAndRenderSubmissionTray('1')
      expect(gradebook.updateRowCellsForStudentIds).toHaveBeenCalledTimes(1)
      expect(gradebook.updateRowCellsForStudentIds).toHaveBeenCalledWith(['1'])
    })

    it('renders the submission tray', () => {
      gradebook.updateRowAndRenderSubmissionTray('1')
      expect(gradebook.renderSubmissionTray).toHaveBeenCalledTimes(1)
    })
  })

  describe('Gradebook#setSubmissionTrayState', () => {
    beforeEach(() => {
      gradebook = createGradebook()
      gradebook.gradebookGrid.gridSupport = {
        helper: {
          commitCurrentEdit: jest.fn(),
          focus: jest.fn(),
        },
      }
    })

    it('sets the state of the submission tray', () => {
      gradebook.setSubmissionTrayState(true, '1', '2')
      const expected = {
        open: true,
        studentId: '1',
        assignmentId: '2',
        commentsLoaded: false,
        comments: [],
        commentsUpdating: false,
        editedCommentId: null,
      }

      expect(gradebook.gridDisplaySettings.submissionTray).toEqual(expected)
    })

    it('puts cell in view mode when tray is opened', () => {
      gradebook.setSubmissionTrayState(true, '1', '2')
      expect(gradebook.gradebookGrid.gridSupport.helper.commitCurrentEdit).toHaveBeenCalledTimes(1)
    })

    it('does not put cell in view mode when tray is closed', () => {
      gradebook.setSubmissionTrayState(false, '1', '2')
      expect(gradebook.gradebookGrid.gridSupport.helper.commitCurrentEdit).not.toHaveBeenCalled()
    })
  })

  describe('Gradebook#getSubmissionTrayState', () => {
    beforeEach(() => {
      gradebook = createGradebook()
    })

    it('returns the state of the submission tray', () => {
      const expected = {
        open: false,
        studentId: '',
        assignmentId: '',
        commentsLoaded: false,
        comments: [],
        commentsUpdating: false,
        editedCommentId: null,
      }

      expect(gradebook.getSubmissionTrayState()).toEqual(expected)
    })

    it('returns the state of the submission tray when accessed directly', () => {
      gradebook.gridDisplaySettings.submissionTray.open = true
      gradebook.gridDisplaySettings.submissionTray.studentId = '1'
      gradebook.gridDisplaySettings.submissionTray.assignmentId = '2'

      const expected = {
        open: true,
        studentId: '1',
        assignmentId: '2',
        commentsLoaded: false,
        comments: [],
        commentsUpdating: false,
        editedCommentId: null,
      }

      expect(gradebook.getSubmissionTrayState()).toEqual(expected)
    })
  })

  describe('Gradebook#toggleSubmissionTrayOpen', () => {
    beforeEach(() => {
      gradebook.gradebookGrid.gridSupport = {
        helper: {
          commitCurrentEdit: jest.fn(),
          focus: jest.fn(),
        },
      }
      jest.spyOn(gradebook, 'updateRowAndRenderSubmissionTray').mockImplementation(() => {})
    })

    it('sets the tray state to open if it was closed', () => {
      const openStateBefore = gradebook.getSubmissionTrayState().open
      gradebook.toggleSubmissionTrayOpen('1', '2')
      const openStateAfter = gradebook.getSubmissionTrayState().open
      expect({before: openStateBefore, after: openStateAfter}).toEqual({
        before: false,
        after: true,
      })
    })

    it('sets the tray state to closed if it was open', () => {
      gradebook.setSubmissionTrayState(true, '1', '2')
      const openStateBefore = gradebook.getSubmissionTrayState().open
      gradebook.toggleSubmissionTrayOpen('1', '2')
      const openStateAfter = gradebook.getSubmissionTrayState().open
      expect({before: openStateBefore, after: openStateAfter}).toEqual({
        before: true,
        after: false,
      })
    })

    it('sets the studentId and assignmentId state for the tray', () => {
      gradebook.toggleSubmissionTrayOpen('1', '2')
      const {studentId, assignmentId} = gradebook.getSubmissionTrayState()
      expect({studentId, assignmentId}).toEqual({studentId: '1', assignmentId: '2'})
    })
  })

  describe('Gradebook#updateSubmissionAndRenderSubmissionTray', () => {
    let promise
    let submission

    beforeEach(() => {
      gradebook = createGradebook()
      gradebook.gradebookGrid.gridSupport = {
        helper: {
          commitCurrentEdit: jest.fn(),
        },
      }
      gradebook.students = {1101: {id: '1101'}}

      promise = {
        then(thenFn) {
          this.thenFn = thenFn
          return this
        },
        catch(catchFn) {
          this.catchFn = catchFn
          return this
        },
      }

      submission = {assignmentId: '2301', latePolicyStatus: 'none', userId: '1101'}
      gradebook.updateSubmission({
        assignment_id: '2301',
        entered_grade: 'A',
        entered_score: 9.5,
        excused: false,
        grade: 'B',
        score: 8.5,
        user_id: '1101',
      })

      jest.spyOn(GradebookApi, 'updateSubmission').mockReturnValue(promise)
      gradebook.setSubmissionTrayState(true, '1101', '2301')
    })

    it('stores the pending grade info before sending the request', () => {
      jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      expect(gradebook.submissionIsUpdating(submission)).toBe(true)
    })

    it('includes "grade" when storing the pending grade info', () => {
      jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      const pendingGradeInfo = gradebook.getPendingGradeInfo(submission)
      expect(pendingGradeInfo.grade).toBe('A')
    })

    it('includes "score" when storing the pending grade info', () => {
      jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      const pendingGradeInfo = gradebook.getPendingGradeInfo(submission)
      expect(pendingGradeInfo.score).toBe(9.5)
    })

    it('includes "excused" when storing the pending grade info', () => {
      jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      const pendingGradeInfo = gradebook.getPendingGradeInfo(submission)
      expect(pendingGradeInfo.excused).toBe(false)
    })

    it('includes "valid" when storing the pending grade info', () => {
      jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      const pendingGradeInfo = gradebook.getPendingGradeInfo(submission)
      expect(pendingGradeInfo.valid).toBe(true)
    })

    it('renders the tray before sending the request', () => {
      const renderTraySpy = jest
        .spyOn(gradebook, 'renderSubmissionTray')
        .mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      expect(renderTraySpy).toHaveBeenCalledTimes(1)
    })

    it('on success the pending grade info is removed', () => {
      jest.spyOn(gradebook, 'renderSubmissionTray').mockImplementation(() => {})
      jest.spyOn(gradebook, 'updateSubmissionsFromExternal').mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      promise.thenFn({data: {all_submissions: [{id: '293', ...submission}]}})
      expect(gradebook.getPendingGradeInfo(submission)).toBeNull()
    })

    it('on success the tray has been rendered a second time', () => {
      const renderTraySpy = jest
        .spyOn(gradebook, 'renderSubmissionTray')
        .mockImplementation(() => {})
      jest.spyOn(gradebook, 'updateSubmissionsFromExternal').mockImplementation(() => {})
      gradebook.updateSubmissionAndRenderSubmissionTray({submission})
      promise.thenFn({data: {all_submissions: [{id: '293', ...submission}]}})
      expect(renderTraySpy).toHaveBeenCalledTimes(2)
    })

    describe('on failure', () => {
      let renderSubmissionTrayStub

      beforeEach(() => {
        renderSubmissionTrayStub = jest
          .spyOn(gradebook, 'renderSubmissionTray')
          .mockImplementation(() => {})
      })

      it('on failure the pending grade info is removed', async () => {
        gradebook.updateSubmissionAndRenderSubmissionTray({submission})
        await promise.catchFn(new Error('A failure')).catch(() => {
          expect(gradebook.getPendingGradeInfo(submission)).toBeNull()
        })
      })

      it('on failure the student row is updated', async () => {
        gradebook.updateSubmissionAndRenderSubmissionTray({submission})
        const updateRowSpy = jest
          .spyOn(gradebook, 'updateRowCellsForStudentIds')
          .mockImplementation(() => {})

        await promise.catchFn(new Error('A failure')).catch(() => {
          expect(updateRowSpy).toHaveBeenCalledTimes(1)
        })
      })

      it('includes the student id when updating its row on failure', async () => {
        gradebook.updateSubmissionAndRenderSubmissionTray({submission})
        const updateRowSpy = jest
          .spyOn(gradebook, 'updateRowCellsForStudentIds')
          .mockImplementation(() => {})

        await promise.catchFn(new Error('A failure')).catch(() => {
          const [userIds] = updateRowSpy.mock.calls[0]
          expect(userIds).toEqual(['1101'])
        })
      })

      it('on failure the submission has been rendered a second time', async () => {
        gradebook.updateSubmissionAndRenderSubmissionTray({submission})
        await promise.catchFn(new Error('A failure')).catch(() => {
          expect(renderSubmissionTrayStub).toHaveBeenCalledTimes(2)
        })
      })

      it('on failure a flash error is triggered', async () => {
        const flashErrorStub = jest.spyOn($, 'flashError').mockImplementation(() => {})
        gradebook.updateSubmissionAndRenderSubmissionTray({submission})
        await promise.catchFn(new Error('A failure')).catch(() => {
          expect(flashErrorStub).toHaveBeenCalledTimes(1)
        })
      })
    })
  })

  describe('Gradebook#renderSubmissionTray - Additional rendering tests', () => {
    let mountPointId

    beforeEach(() => {
      mountPointId = 'StudentTray__Container'
      document.body.innerHTML = `<div id="${mountPointId}"></div>`

      server.use(http.get('*', () => HttpResponse.json({submission_comments: []})))

      gradebook = createGradebook()

      gradebook.setAssignments({
        2301: {
          id: '2301',
          assignment_group_id: '9000',
          course_id: '1',
          grading_type: 'points',
          name: 'Assignment 1',
          assignment_visibility: [],
          only_visible_to_overrides: false,
          html_url: 'http://assignmentUrl',
          muted: false,
          omit_from_final_grade: false,
          published: true,
          submission_types: ['online_text_entry'],
          anonymize_students: false,
          post_manually: false,
        },
      })
      gradebook.setAssignmentGroups({9000: {group_weight: 100}})

      gradebook.students = {
        1101: {
          id: '1101',
          name: "J'onn J'onzz",
          assignment_2301: {
            assignment_id: '2301',
            late: false,
            missing: false,
            excused: false,
            workflow_state: 'submitted',
          },
          enrollments: [{grades: {html_url: 'http://gradesUrl/'}}],
          isConcluded: false,
        },
      }

      jest.spyOn(gradebook, 'listRows').mockImplementation(() => [gradebook.students[1101]])

      gradebook.gradebookGrid.gridSupport = {
        helper: {
          commitCurrentEdit: jest.fn(),
          focus: jest.fn(),
        },
        state: {
          getActiveLocation: () => ({region: 'body', cell: 0, row: 0}),
        },
        grid: {
          getColumns: () => [],
        },
      }

      jest.useFakeTimers()

      global.ENV = {
        ...global.ENV,
        GRADEBOOK_OPTIONS: {
          ...global.ENV?.GRADEBOOK_OPTIONS,
          has_modules: true,
          post_manually: false,
        },
      }

      jest.spyOn(global, 'fetch').mockImplementation(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({submission_comments: []}),
        }),
      )
    })

    afterEach(() => {
      jest.useRealTimers()
      const node = document.getElementById(mountPointId)
      if (node) {
        ReactDOM.unmountComponentAtNode(node)
        node.remove()
      }
      jest.restoreAllMocks()
    })

    it('shows a submission tray on the page when rendering an open tray', async () => {
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))

      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })
    })

    it('does not show a submission tray on the page when rendering a closed tray', () => {
      jest.useFakeTimers()
      gradebook.setSubmissionTrayState(false, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))
      jest.advanceTimersByTime(500)
      // Using queryByLabelText because it won't throw if not found
      expect(screen.queryByLabelText('Submission tray')).toBeNull()
      jest.useRealTimers()
    })

    it('shows a submission tray when the related submission has not loaded for the student', async () => {
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const student = gradebook.student('1101')
      student.assignment_2301 = {
        assignment_id: '2301',
        late: false,
        missing: false,
        excused: false,
        workflow_state: 'unsubmitted',
      }
      gradebook.renderSubmissionTray(student)
      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })
    })
  })

  describe('Gradebook#closeSubmissionTray', () => {
    let activeStudentId

    beforeEach(() => {
      gradebook = createGradebook()
      activeStudentId = '1101'

      gradebook.gridData = {
        rows: [{id: activeStudentId}],
      }

      gradebook.gradebookGrid = {
        grid: {
          getActiveCell: () => ({row: 0}),
        },
        gridSupport: {
          helper: {
            commitCurrentEdit: jest.fn(),
            focus: jest.fn(),
            beginEdit: jest.fn(),
          },
        },
      }

      gradebook.setSubmissionTrayState(true, activeStudentId, '2')
      jest.spyOn(gradebook, 'updateRowAndRenderSubmissionTray').mockImplementation(() => {})
    })

    it('puts the active grid cell back into "editing" mode', () => {
      const beginEditSpy = jest.spyOn(gradebook.gradebookGrid.gridSupport.helper, 'beginEdit')

      gradebook.closeSubmissionTray()

      expect(beginEditSpy).toHaveBeenCalledTimes(1)
    })
  })

  describe('Gradebook#renderSubmissionTray - Student Carousel', () => {
    let mountPointId

    beforeEach(() => {
      mountPointId = 'StudentTray__Container'
      document.body.innerHTML = `<div id="${mountPointId}"></div>`

      server.use(
        http.get(/\/api\/v1\/courses\/.*/, () => HttpResponse.json({submission_comments: []})),
      )

      gradebook = createGradebook()

      gradebook.setAssignments({
        2301: {
          id: '2301',
          assignment_group_id: '9000',
          course_id: '1',
          grading_type: 'points',
          name: 'Assignment 1',
          assignment_visibility: [],
          only_visible_to_overrides: false,
          html_url: 'http://assignmentUrl',
          muted: false,
          omit_from_final_grade: false,
          published: true,
          submission_types: ['online_text_entry'],
          anonymize_students: false,
          post_manually: false,
        },
      })
      gradebook.setAssignmentGroups({9000: {group_weight: 100}})

      gradebook.students = {
        1100: {
          id: '1100',
          name: 'Adam Jones',
          assignment_2301: {
            assignment_id: '2301',
            late: false,
            missing: false,
            excused: false,
            workflow_state: 'submitted',
          },
          enrollments: [{grades: {html_url: 'http://gradesUrl/'}}],
          isConcluded: false,
        },
        1101: {
          id: '1101',
          name: 'Adam Jones',
          assignment_2301: {
            assignment_id: '2301',
            late: false,
            missing: false,
            excused: false,
            workflow_state: 'submitted',
          },
          enrollments: [{grades: {html_url: 'http://gradesUrl/'}}],
          isConcluded: false,
        },
        1102: {
          id: '1102',
          name: 'Adam Jones',
          assignment_2301: {
            assignment_id: '2301',
            late: false,
            missing: false,
            excused: false,
            workflow_state: 'submitted',
          },
          enrollments: [{grades: {html_url: 'http://gradesUrl/'}}],
          isConcluded: false,
        },
      }

      jest
        .spyOn(gradebook, 'listRows')
        .mockImplementation(() => [
          gradebook.students[1100],
          gradebook.students[1101],
          gradebook.students[1102],
        ])

      gradebook.gradebookGrid.gridSupport = {
        helper: {
          commitCurrentEdit: jest.fn(),
          focus: jest.fn(),
        },
        state: {
          getActiveLocation: () => ({region: 'body', cell: 0, row: 0}),
        },
        grid: {
          getColumns: () => [],
        },
      }

      jest.useFakeTimers()
    })

    afterEach(() => {
      jest.useRealTimers()
      const node = document.getElementById(mountPointId)
      if (node) {
        ReactDOM.unmountComponentAtNode(node)
        node.remove()
      }
      jest.restoreAllMocks()
    })

    it('does not show the previous student arrow for the first student', async () => {
      gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
        region: 'body',
        cell: 0,
        row: 0,
      })
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))

      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })

      const prevArrowButtons = document.querySelectorAll(
        '#student-carousel .left-arrow-button-container button',
      )
      expect(prevArrowButtons).toHaveLength(0)
    })

    it('shows the next student arrow for the first student', async () => {
      gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
        region: 'body',
        cell: 0,
        row: 0,
      })
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))

      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })

      const nextArrowButtons = document.querySelectorAll(
        '#student-carousel .right-arrow-button-container button',
      )
      expect(nextArrowButtons).toHaveLength(1)
    })

    it('does not show the next student arrow for the last student', async () => {
      gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
        region: 'body',
        cell: 0,
        row: 2,
      })
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))

      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })

      const nextArrowButtons = document.querySelectorAll(
        '#student-carousel .right-arrow-button-container button',
      )
      expect(nextArrowButtons).toHaveLength(0)
    })

    it('shows the previous student arrow for the last student', async () => {
      gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
        region: 'body',
        cell: 0,
        row: 2,
      })
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))

      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })

      const prevArrowButtons = document.querySelectorAll(
        '#student-carousel .left-arrow-button-container button',
      )
      expect(prevArrowButtons).toHaveLength(1)
    })

    it('clicking the next student arrow calls loadTrayStudent with "next"', async () => {
      jest.spyOn(gradebook, 'loadTrayStudent').mockImplementation(() => {})
      jest.spyOn(gradebook, 'getCommentsUpdating').mockReturnValue(false)
      jest.spyOn(gradebook, 'getSubmissionCommentsLoaded').mockReturnValue(true)

      gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
        region: 'body',
        cell: 0,
        row: 1,
      })
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))

      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })

      const nextButton = document.querySelector(
        '#student-carousel .right-arrow-button-container button',
      )
      nextButton.click()

      expect(gradebook.loadTrayStudent).toHaveBeenCalledTimes(1)
      expect(gradebook.loadTrayStudent).toHaveBeenCalledWith('next')
    })

    it('clicking the previous student arrow calls loadTrayStudent with "previous"', async () => {
      jest.spyOn(gradebook, 'loadTrayStudent').mockImplementation(() => {})
      jest.spyOn(gradebook, 'getCommentsUpdating').mockReturnValue(false)
      jest.spyOn(gradebook, 'getSubmissionCommentsLoaded').mockReturnValue(true)

      gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
        region: 'body',
        cell: 0,
        row: 1,
      })
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))

      await waitFor(() => {
        expect(screen.getByLabelText('Submission tray')).toBeInTheDocument()
      })

      const prevButton = document.querySelector(
        '#student-carousel .left-arrow-button-container button',
      )
      prevButton.click()

      expect(gradebook.loadTrayStudent).toHaveBeenCalledTimes(1)
      expect(gradebook.loadTrayStudent).toHaveBeenCalledWith('previous')
    })

    it('calls loadSubmissionComments', () => {
      const loadSubmissionCommentsStub = jest
        .spyOn(gradebook, 'loadSubmissionComments')
        .mockImplementation(() => {})
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))
      expect(loadSubmissionCommentsStub).toHaveBeenCalledTimes(1)
    })

    it('does not call loadSubmissionComments if not open', () => {
      const loadSubmissionCommentsStub = jest
        .spyOn(gradebook, 'loadSubmissionComments')
        .mockImplementation(() => {})
      gradebook.setSubmissionTrayState(false, '1101', '2301')
      gradebook.renderSubmissionTray(gradebook.student('1101'))
      expect(loadSubmissionCommentsStub).not.toHaveBeenCalled()
    })

    it('does not call loadSubmissionComments if loaded', () => {
      const loadSubmissionCommentsStub = jest
        .spyOn(gradebook, 'loadSubmissionComments')
        .mockImplementation(() => {})
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      gradebook.setSubmissionCommentsLoaded(true)
      gradebook.renderSubmissionTray(gradebook.student('1101'))
      expect(loadSubmissionCommentsStub).not.toHaveBeenCalled()
    })
  })
})

describe('calculateCheckpointStates', () => {
  it('rounds up late hours', () => {
    const SECONDS_IN_HOUR = 3600
    const result = calculateCheckpointStates(
      {
        subAssignmentSubmissions: [
          {
            seconds_late: SECONDS_IN_HOUR * 5 + 1,
            late: true,
          },
        ],
      },
      {
        lateSubmissionInterval: 'hour',
      },
    )

    expect(result[0].timeLate).toEqual('6')
  })

  it('rounds up late days', () => {
    const SECONDS_IN_DAY = 24 * 3600
    const result = calculateCheckpointStates(
      {
        subAssignmentSubmissions: [
          {
            seconds_late: SECONDS_IN_DAY * 5 + 1,
            late: true,
          },
        ],
      },
      {
        lateSubmissionInterval: 'day',
      },
    )

    expect(result[0].timeLate).toEqual('6')
  })
})
