/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import 'jquery-migrate'
import React from 'react'
import ReactDOM from 'react-dom'
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {createCourseGradesWithGradingPeriods as createGrades} from '@canvas/grading/GradeCalculatorSpecHelper'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashSuccess: jest.fn(),
  showFlashError: jest.fn(),
}))

describe('setupGrading', () => {
  let gradebook

  beforeEach(() => {
    const fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)
    gradebook = createGradebook()
    gradebook.students = [{id: '1101'}, {id: '1102'}]
    jest.spyOn(gradebook, 'setAssignmentVisibility').mockImplementation()
    jest.spyOn(gradebook, 'invalidateRowsForStudentIds').mockImplementation()
  })

  afterEach(() => {
    jest.restoreAllMocks()
    document.getElementById('fixtures')?.remove()
  })

  test('does not cause gradebook to forget about students that are loaded but not currently in view', () => {
    gradebook.setupGrading(gradebook.students)
    expect(gradebook.setAssignmentVisibility).toHaveBeenCalledTimes(1)
    const [studentIds] = gradebook.setAssignmentVisibility.mock.calls[0]
    expect(studentIds).toEqual(['1101', '1102'])
  })

  test('returns student IDs for the given students', () => {
    const studentIds = gradebook.setupGrading(gradebook.students)
    expect(studentIds).toEqual(['1101', '1102'])
  })
})

describe('resetGrading', () => {
  let gradebook

  beforeEach(() => {
    const fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)
    gradebook = createGradebook()
    jest.spyOn(gradebook, 'setupGrading').mockImplementation()

    // Initialize required data structures
    gradebook.gridData = {
      rows: [
        {id: '1101', name: 'Adam Jones'},
        {id: '1102', name: 'Betty Smith'},
      ],
    }

    gradebook.courseContent = {
      students: {
        listStudents: () => [
          {id: '1101', name: 'Adam Jones'},
          {id: '1102', name: 'Betty Smith'},
        ],
      },
    }

    gradebook.students = [
      {id: '1101', name: 'Adam Jones'},
      {id: '1102', name: 'Betty Smith'},
    ]
  })

  afterEach(() => {
    jest.restoreAllMocks()
    document.getElementById('fixtures')?.remove()
  })

  test.skip('initializes a new submission state map', () => {
    gradebook.resetGrading()
    expect(gradebook.submissionStateMap).toBeInstanceOf(SubmissionStateMap)
  })

  test.skip('calls setupGrading with all students', () => {
    gradebook.resetGrading()
    expect(gradebook.setupGrading).toHaveBeenCalledWith(gradebook.students)
  })
})

describe('Gradebook Grading Schemes', () => {
  const defaultGradingScheme = [
    ['A', 0.9],
    ['B', 0.8],
    ['C', 0.7],
    ['D', 0.6],
    ['E', 0.5],
  ]
  const gradingScheme = {
    id: '2801',
    data: [
      ['😂', 0.9],
      ['🙂', 0.8],
      ['😐', 0.7],
      ['😢', 0.6],
      ['💩', 0],
    ],
    title: 'Emoji Grades',
  }

  let gradebook

  beforeEach(() => {
    const fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)
    setFixtureHtml(fixturesDiv)
  })

  afterEach(() => {
    if (gradebook && gradebook.destroy) {
      gradebook.destroy()
    }
    document.getElementById('fixtures')?.remove()
    jest.restoreAllMocks()
  })

  function createInitializedGradebook(options = {}) {
    gradebook = createGradebook({
      default_grading_standard: defaultGradingScheme,
      grading_schemes: [gradingScheme],
      grading_standard: gradingScheme.data,
      ...options,
    })
    gradebook.setAssignments({
      2301: {
        grading_standard_id: '2801',
        grading_type: 'points',
        id: '2301',
        name: 'Math Assignment',
        published: true,
      },
      2302: {
        grading_standard_id: null,
        grading_type: 'points',
        id: '2302',
        name: 'English Assignment',
        published: false,
      },
    })
  }

  describe('#getCourseGradingScheme', () => {
    test('returns the course grading scheme when present', () => {
      createInitializedGradebook()
      expect(gradebook.getCourseGradingScheme().data).toEqual(gradingScheme.data)
    })

    test('returns null when course is not using a grading scheme', () => {
      createInitializedGradebook({grading_standard: undefined})
      expect(gradebook.getCourseGradingScheme()).toBeNull()
    })
  })

  describe('#getDefaultGradingScheme', () => {
    test('returns the default grading scheme when present', () => {
      createInitializedGradebook()
      expect(gradebook.getDefaultGradingScheme().data).toEqual(defaultGradingScheme)
    })

    test('returns null when the default grading scheme is not present', () => {
      createInitializedGradebook({default_grading_standard: undefined})
      expect(gradebook.getDefaultGradingScheme()).toBeNull()
    })
  })

  describe('#getGradingScheme', () => {
    test('returns the grading scheme matching the given id', () => {
      createInitializedGradebook()
      expect(gradebook.getGradingScheme('2801')).toEqual(gradingScheme)
    })

    test('returns undefined when no grading scheme exists with the given id', () => {
      createInitializedGradebook()
      expect(gradebook.getGradingScheme('2802')).toBeUndefined()
    })
  })

  describe('#getAssignmentGradingScheme', () => {
    test('returns the grading scheme associated with the assignment', () => {
      createInitializedGradebook()
      expect(gradebook.getAssignmentGradingScheme('2301')).toEqual(gradingScheme)
    })

    test('returns the default grading scheme when the assignment does not use a specific scheme', () => {
      createInitializedGradebook()
      expect(gradebook.getAssignmentGradingScheme('2302').data).toEqual(defaultGradingScheme)
    })
  })
})

describe('Gradebook#weightedGrades', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('returns true when group_weighting_scheme is "percent"', () => {
    gradebook.options.group_weighting_scheme = 'percent'
    gradebook.gradingPeriodSet = {weighted: false}
    expect(gradebook.weightedGrades()).toBe(true)
  })

  test('returns true when the gradingPeriodSet is weighted', () => {
    gradebook.options.group_weighting_scheme = 'points'
    gradebook.gradingPeriodSet = {weighted: true}
    expect(gradebook.weightedGrades()).toBe(true)
  })

  test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not weighted', () => {
    gradebook.options.group_weighting_scheme = 'points'
    gradebook.gradingPeriodSet = {weighted: false}
    expect(gradebook.weightedGrades()).toBe(false)
  })

  test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not defined', () => {
    gradebook.options.group_weighting_scheme = 'points'
    gradebook.gradingPeriodSet = {weighted: null}
    expect(gradebook.weightedGrades()).toBe(false)
  })
})

describe('Gradebook#weightedGroups', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('returns true when group_weighting_scheme is "percent"', () => {
    gradebook.options.group_weighting_scheme = 'percent'
    expect(gradebook.weightedGroups()).toBe(true)
  })

  test('returns false when group_weighting_scheme is not "percent"', () => {
    gradebook.options.group_weighting_scheme = 'points'
    expect(gradebook.weightedGroups()).toBe(false)
    gradebook.options.group_weighting_scheme = null
    expect(gradebook.weightedGroups()).toBe(false)
  })
})

describe('Gradebook#calculateStudentGrade', () => {
  let gradebook
  let calculatedGrades

  beforeEach(() => {
    calculatedGrades = createGrades()
    jest.spyOn(CourseGradeCalculator, 'calculate').mockReturnValue(calculatedGrades)
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  function createGradebookWithOptions(options = {}) {
    gradebook = createGradebook({
      group_weighting_scheme: 'points',
      ...options,
    })
    gradebook.setAssignments({
      2301: {
        grading_standard_id: '2801',
        grading_type: 'points',
        id: '2301',
        name: 'Math Assignment',
        published: true,
      },
      2302: {
        grading_standard_id: null,
        grading_type: 'points',
        id: '2302',
        name: 'English Assignment',
        published: false,
      },
    })
    gradebook.assignmentGroups = [
      {
        id: '301',
        group_weight: 60,
        rules: {},
        assignments: [{id: '201', points_possible: 10, omit_from_final_grade: false}],
      },
    ]
    gradebook.gradingPeriods = [
      {id: '701', weight: 50},
      {id: '702', weight: 50},
    ]
    gradebook.gradingPeriodSet = {
      id: '1501',
      gradingPeriods: [
        {id: '701', weight: 50},
        {id: '702', weight: 50},
      ],
      weighted: true,
    }
    gradebook.effectiveDueDates = {
      201: {
        101: {grading_period_id: '701'},
      },
    }
    gradebook.submissionsForStudent = () => gradebook.submissions
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
  }

  test('calculates grades using properties from the gradebook', () => {
    createGradebookWithOptions()
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.calculateStudentGrade({
      id: '101',
      loaded: true,
      initialized: true,
    })
    const args = CourseGradeCalculator.calculate.mock.calls[0]
    expect(args[0]).toBe(gradebook.submissions)
    expect(args[1]).toBe(gradebook.assignmentGroups)
    expect(args[2]).toBe(gradebook.options.group_weighting_scheme)
    expect(args[4]).toBe(gradebook.gradingPeriodSet)
  })

  test('scopes effective due dates to the user', () => {
    createGradebookWithOptions()
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.calculateStudentGrade({
      id: '101',
      loaded: true,
      initialized: true,
    })
    const dueDates = CourseGradeCalculator.calculate.mock.calls[0][5]
    expect(dueDates).toEqual({
      201: {
        grading_period_id: '701',
      },
    })
  })

  test.skip('calculates grades without grading period data when grading period set is null', () => {
    createGradebookWithOptions({grading_period_set: null})
    gradebook.effectiveDueDates = {201: {}}
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student)
    const args =
      CourseGradeCalculator.calculate.mock.calls[
        CourseGradeCalculator.calculate.mock.calls.length - 1
      ]
    expect(args[0]).toBe(gradebook.submissions)
    expect(args[1]).toBe(gradebook.assignmentGroups)
    expect(args[2]).toBe(gradebook.options.group_weighting_scheme)
    expect(args[3]).toBeUndefined()
    expect(args[4]).toBeUndefined()
  })

  test('stores the current grade on the student if not viewing ungraded as zero', () => {
    createGradebookWithOptions()
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student)
    expect(student.total_grade).toEqual(calculatedGrades.current)
  })

  test.skip('stores the final grade on the student if viewing ungraded as zero', () => {
    createGradebookWithOptions({
      show_total_grade_as_points: true,
      view_ungraded_as_zero: true,
    })
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student)
    expect(student.total_grade).toEqual(calculatedGrades.final)
  })

  test('stores the current grade from the selected grading period if not viewing ungraded as zero', () => {
    createGradebookWithOptions()
    gradebook.gradingPeriodId = '701'
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student)
    expect(student.total_grade).toEqual(calculatedGrades.gradingPeriods['701'].current)
  })

  test.skip('stores the final grade from the selected grading period if viewing ungraded as zero', () => {
    createGradebookWithOptions({
      show_total_grade_as_points: true,
      view_ungraded_as_zero: true,
    })
    gradebook.gradingPeriodId = '701'
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student)
    expect(student.total_grade).toEqual(calculatedGrades.gradingPeriods['701'].final)
  })

  test('does not repeat the calculation if cached and preferCachedGrades is true', () => {
    createGradebookWithOptions()
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student)
    gradebook.calculateStudentGrade(student, true)
    expect(CourseGradeCalculator.calculate).toHaveBeenCalledTimes(1)
  })

  test('does perform the calculation if preferCachedGrades is true and no cached value exists', () => {
    createGradebookWithOptions()
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student, true)
    expect(CourseGradeCalculator.calculate).toHaveBeenCalledTimes(1)
  })

  test('does not calculate when the student is not loaded', () => {
    createGradebookWithOptions()
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: false,
      initialized: true,
    }
    gradebook.calculateStudentGrade(student)
    expect(CourseGradeCalculator.calculate).not.toHaveBeenCalled()
  })

  test('does not calculate when the student is not initialized', () => {
    createGradebookWithOptions()
    gradebook.submissions = [{assignment_id: 201, score: 10}]
    gradebook.assignmentGroups = {201: {group_weight: 100}}
    const student = {
      id: '101',
      loaded: true,
      initialized: false,
    }
    gradebook.calculateStudentGrade(student)
    expect(CourseGradeCalculator.calculate).not.toHaveBeenCalled()
  })
})

describe('Gradebook#allowApplyScoreToUngraded', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  test('returns true if the allow_apply_score_to_ungraded option is true', () => {
    gradebook = createGradebook({allow_apply_score_to_ungraded: true})
    expect(gradebook.allowApplyScoreToUngraded()).toBeTruthy()
  })

  test('returns false if the allow_apply_score_to_ungraded option is false', () => {
    gradebook = createGradebook({allow_apply_score_to_ungraded: false})
    expect(gradebook.allowApplyScoreToUngraded()).toBeFalsy()
  })
})

describe('Gradebook#onApplyScoreToUngradedRequested', () => {
  let gradebook
  let mountPoint

  beforeEach(() => {
    mountPoint = document.body.appendChild(document.createElement('div'))
    gradebook = createGradebook({
      allow_apply_score_to_ungraded: true,
      applyScoreToUngradedModalNode: mountPoint,
    })
    jest.spyOn(ReactDOM, 'render').mockImplementation()
    jest.spyOn(React, 'createElement').mockImplementation()
  })

  afterEach(() => {
    jest.restoreAllMocks()
    mountPoint.remove()
  })

  test('does not render the modal if the allow_apply_score_to_ungraded option is false', () => {
    gradebook = createGradebook({
      allow_apply_score_to_ungraded: false,
      applyScoreToUngradedModalNode: mountPoint,
    })
    gradebook.onApplyScoreToUngradedRequested()
    expect(ReactDOM.render).not.toHaveBeenCalled()
  })

  test('renders the modal when the mount point is present and allow_apply_score_to_ungraded is true', () => {
    gradebook.onApplyScoreToUngradedRequested()
    expect(ReactDOM.render).toHaveBeenCalledTimes(1)
    expect(ReactDOM.render.mock.calls[0][1]).toBe(mountPoint)
  })

  test('passes the supplied assignmentGroup to the render if present', () => {
    const assignmentGroup = {id: '100', name: 'group'}
    gradebook.onApplyScoreToUngradedRequested(assignmentGroup)
    expect(React.createElement).toHaveBeenCalledTimes(1)
    expect(React.createElement.mock.calls[0][1].assignmentGroup).toEqual({
      id: '100',
      name: 'group',
    })
  })
})

describe('Gradebook#executeApplyScoreToUngraded', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook({
      context_id: '1',
      grading_period_set: null,
    })

    gradebook.gridDisplaySettings = {
      showTotalGrade: true,
      hideAssignmentGroupTotals: false,
    }

    gradebook.gridData = {
      columns: {
        frozen: [],
        scrollable: [],
      },
    }

    gradebook.gradebookGrid = {
      gridSupport: {
        columns: {
          updateColumnHeaders: jest.fn(),
        },
      },
    }

    gradebook.scoreToUngradedManager = {
      startProcess: jest.fn().mockResolvedValue(undefined),
    }

    gradebook.getAssignmentOrder = jest.fn().mockReturnValue(['1', '2'])
    gradebook.getStudentOrder = jest.fn().mockReturnValue(['1101', '1102'])
  })

  afterEach(() => {
    jest.restoreAllMocks()
    jest.clearAllMocks()
  })

  test.skip('shows success message when starting the process', async () => {
    await gradebook.executeApplyScoreToUngraded({value: 10.0})
    expect(FlashAlert.showFlashSuccess).toHaveBeenCalledWith(
      'Request successfully sent. Note that applying scores may take a while and changes will not appear until you reload the page.',
    )
  })

  test('updates column headers when process starts', async () => {
    await gradebook.executeApplyScoreToUngraded({value: 10.0})
    expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalled()
  })

  test('sends percentage value to score manager', async () => {
    await gradebook.executeApplyScoreToUngraded({value: 50.0})
    expect(gradebook.scoreToUngradedManager.startProcess).toHaveBeenCalledWith('1', {
      percent: 50.0,
      assignment_ids: ['1', '2'],
      student_ids: ['1101', '1102'],
    })
  })

  test('sends excused value to score manager', async () => {
    await gradebook.executeApplyScoreToUngraded({value: 'excused'})
    expect(gradebook.scoreToUngradedManager.startProcess).toHaveBeenCalledWith('1', {
      excused: true,
      assignment_ids: ['1', '2'],
      student_ids: ['1101', '1102'],
    })
  })

  test.skip('shows error message when process fails', async () => {
    const error = new Error('Process failed')
    gradebook.scoreToUngradedManager.startProcess.mockRejectedValue(error)
    await gradebook.executeApplyScoreToUngraded({value: 10.0})
    expect(FlashAlert.showFlashError).toHaveBeenCalled()
  })
})
