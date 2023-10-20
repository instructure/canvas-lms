// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import {render, within} from '@testing-library/react'
import {defaultGradebookProps} from '../../__tests__/GradebookSpecHelper'
import {darken, defaultColors} from '../../constants/colors'
import Gradebook from '../../Gradebook'
import store from '../../stores/index'
import {AssignmentGroup, Student} from '../../../../../../api.d'
import '@testing-library/jest-dom/extend-expect'

const originalState = store.getState()

describe('Gradebook', () => {
  beforeEach(() => {
    fetchMock.mock('*', 200)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('renders', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gradebookMenuNode={node} />)
    const {getByText} = within(node)
    expect(node).toContainElement(getByText(/Gradebook/i))
  })
})

describe('SettingsModalButton', () => {
  it('renders', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} settingsModalButtonContainer={node} />)
    const {getByText} = within(node)
    expect(node).toContainElement(getByText(/Gradebook Settings/i))
  })
})

describe('GridColor', () => {
  it('renders', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gridColorNode={node} />)
    const {getByTestId} = within(node)
    expect(node).toContainElement(getByTestId('grid-color'))
  })

  it('renders the correct styles', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gridColorNode={node} />)
    const styleText = [
      `.even .gradebook-cell.late { background-color: ${defaultColors.blue}; }`,
      `.odd .gradebook-cell.late { background-color: ${darken(defaultColors.blue, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.late { background-color: white; }',
      `.even .gradebook-cell.missing { background-color: ${defaultColors.salmon}; }`,
      `.odd .gradebook-cell.missing { background-color: ${darken(defaultColors.salmon, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.missing { background-color: white; }',
      `.even .gradebook-cell.resubmitted { background-color: ${defaultColors.green}; }`,
      `.odd .gradebook-cell.resubmitted { background-color: ${darken(defaultColors.green, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.resubmitted { background-color: white; }',
      `.even .gradebook-cell.dropped { background-color: ${defaultColors.orange}; }`,
      `.odd .gradebook-cell.dropped { background-color: ${darken(defaultColors.orange, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.dropped { background-color: white; }',
      `.even .gradebook-cell.excused { background-color: ${defaultColors.yellow}; }`,
      `.odd .gradebook-cell.excused { background-color: ${darken(defaultColors.yellow, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.excused { background-color: white; }',
    ].join('')
    expect(node.innerHTML).toContain(styleText)
  })

  describe('FlashAlert', () => {
    it('renders flash alerts if the flashAlerts prop has content', () => {
      const node = document.createElement('div')
      const alert = {key: 'alert', message: 'Uh oh!', variant: 'error'}
      render(
        <Gradebook {...defaultGradebookProps} flashAlerts={[alert]} flashMessageContainer={node} />
      )
      const {getByText} = within(node)
      expect(node).toContainElement(getByText(/Uh oh!/i))
    })
  })
})

describe('ExportProgressBar', () => {
  it('renders', () => {
    const {getByTestId} = render(<Gradebook {...defaultGradebookProps} />)
    expect(getByTestId('export-progress-bar')).toBeInTheDocument()
  })
})

const assignmentGroups: AssignmentGroup[] = [
  {
    id: '4',
    name: 'Assignments',
    position: 1,
    group_weight: 0,
    sis_source_id: null,
    integration_data: {},
    rules: {},
    assignments: [
      {
        id: '135',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        points_possible: 10,
        grading_type: 'points',
        assignment_group_id: '4',
        grading_standard_id: null,
        created_at: '2022-10-17T18:07:04Z',
        updated_at: '2022-11-17T22:01:25Z',
        peer_reviews: true,
        automatic_peer_reviews: false,
        position: 15,
        grade_group_students_individually: false,
        anonymous_peer_reviews: false,
        group_category_id: null,
        post_to_sis: false,
        moderated_grading: false,
        omit_from_final_grade: false,
        intra_group_peer_reviews: false,
        anonymous_instructor_annotations: false,
        anonymous_grading: false,
        graders_anonymous_to_graders: false,
        grader_count: 0,
        grader_comments_visible_to_graders: true,
        final_grader_id: null,
        grader_names_visible_to_final_grader: true,
        allowed_attempts: -1,
        annotatable_attachment_id: null,
        secure_params:
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsdGlfYXNzaWdubWVudF9pZCI6ImIwY2ZhZDBkLThjNTktNDRhMS1iNTNjLTY1ZjI0N2Y5MGViYiIsImx0aV9hc3NpZ25tZW50X2Rlc2NyaXB0aW9uIjoiIn0.9SnL8X-tPwMIRGDkT3bpNxp-93145z7NMicOdoToDTQ',
        lti_context_id: 'b0cfad0d-8c59-44a1-b53c-65f247f90ebb',
        course_id: '4',
        name: 'Media Assignment',
        submission_types: ['media_recording'],
        has_submitted_submissions: false,
        due_date_required: false,
        max_name_length: 255,
        grades_published: true,
        graded_submissions_exist: true,
        is_quiz_assignment: false,
        can_duplicate: true,
        original_course_id: null,
        original_assignment_id: null,
        original_lti_resource_link_id: null,
        original_assignment_name: null,
        original_quiz_id: null,
        workflow_state: 'published',
        important_dates: false,
        muted: true,
        html_url: 'http://canvas.docker/courses/4/assignments/135',
        has_overrides: false,
        sis_assignment_id: null,
        integration_id: null,
        integration_data: {},
        allowed_extensions: ['pdf'],
        module_ids: [],
        module_positions: [],
        published: true,
        unpublishable: true,
        only_visible_to_overrides: false,
        assignment_visibility: [],
        locked_for_user: false,
        submissions_download_url:
          'http://canvas.docker/courses/4/assignments/135/submissions?zip=1',
        post_manually: false,
        anonymize_students: false,
        require_lockdown_browser: false,
      },
    ],
  },
]

describe('assignments-filter', () => {
  it('renders Assignment Names label', () => {
    const {getByText, rerender} = render(<Gradebook {...defaultGradebookProps} />)

    rerender(
      <Gradebook
        {...defaultGradebookProps}
        recentlyLoadedAssignmentGroups={{
          assignmentGroups: [],
        }}
      />
    )

    expect(getByText(/Assignment Names/)).toBeInTheDocument()
  })

  it('disables the input if the grid has not yet rendered', function () {
    const {getByTestId, rerender} = render(<Gradebook {...defaultGradebookProps} />)

    rerender(
      <Gradebook
        {...defaultGradebookProps}
        recentlyLoadedAssignmentGroups={{
          assignmentGroups,
        }}
      />
    )
    expect(getByTestId('assignments-filter-select')).toBeDisabled()
  })
})

describe('student-names-filter', () => {
  it('renders Student Names label', () => {
    const {getByText, rerender} = render(<Gradebook {...defaultGradebookProps} />)

    rerender(<Gradebook {...defaultGradebookProps} recentlyLoadedStudents={[]} />)

    expect(getByText(/Student Names/)).toBeInTheDocument()
  })

  const students: Student[] = [
    {
      id: '28',
      name: 'Ganondorf',
      created_at: '2022-07-05T14:11:48-06:00',
      sortable_name: 'Ganondorf',
      short_name: 'Ganondorf',
      sis_user_id: null,
      integration_id: null,
      sis_import_id: null,
      login_id: '9088409122',
      section_ids: [],
      last_name: '',
      first_name: 'Ganondorf',
      enrollments: [
        {
          id: '27',
          user_id: '28',
          course_id: '4',
          type: 'StudentEnrollment',
          created_at: '2022-07-05T20:11:49Z',
          updated_at: '2022-07-05T20:11:51Z',
          associated_user_id: null,
          start_at: null,
          end_at: null,
          course_section_id: '10',
          root_account_id: '2',
          limit_privileges_to_course_section: false,
          enrollment_state: 'active',
          role_id: '19',
          last_activity_at: '2022-11-30T23:51:09Z',
          last_attended_at: null,
          total_activity_time: 43233,
          sis_import_id: null,
          grades: {
            html_url: 'http://canvas.docker/courses/4/grades/28',
            current_grade: null,
            current_score: 53.33,
            final_grade: null,
            final_score: 53.33,
            unposted_current_score: 53.33,
            unposted_current_grade: null,
            unposted_final_score: 53.33,
            unposted_final_grade: null,
          },
          sis_account_id: null,
          sis_course_id: null,
          course_integration_id: null,
          sis_section_id: null,
          section_integration_id: null,
          sis_user_id: null,
          html_url: 'http://canvas.docker/courses/4/users/28',
        },
      ],
      email: null,
      group_ids: ['2', '3', '5'],
    },
  ]

  it('disables the input if the grid has not yet rendered', function () {
    const {getByTestId, rerender} = render(<Gradebook {...defaultGradebookProps} />)

    rerender(<Gradebook {...defaultGradebookProps} recentlyLoadedStudents={students} />)

    expect(getByTestId('students-filter-select')).toBeDisabled()
  })
})

describe('ProgressBar for loading data', () => {
  it('do not render the progress bar if submission data loaded', () => {
    const {queryByTestId} = render(
      <Gradebook
        {...defaultGradebookProps}
        isSubmissionDataLoaded={true}
        totalSubmissionsLoaded={0}
        totalStudentsToLoad={11}
      />
    )

    expect(queryByTestId('gradebook-submission-progress-bar')).not.toBeInTheDocument()
  })

  it('renders the progress bar with the correct screenreader label', () => {
    const assignmentMap = {}

    for (let i = 0; i < 200; i++) {
      assignmentMap[i] = {}
    }

    const {getByRole} = render(
      <Gradebook
        {...defaultGradebookProps}
        assignmentMap={assignmentMap}
        isGridLoaded={true}
        isSubmissionDataLoaded={false}
        totalStudentsToLoad={300}
        totalSubmissionsLoaded={0}
      />
    )

    expect(getByRole('progressbar')).toHaveAttribute(
      'aria-label',
      'Loading Gradebook submissions 0 / 60000'
    )
  })
})

describe('TotalGradeOverrideTrayProvider tests', () => {
  it('should render the total grade override tray with FF ON', async () => {
    store.setState({
      finalGradeOverrideTrayProps: {
        isOpen: true,
        studentInfo: {id: '1', name: 'Test Student'},
      },
    })
    const gradeBookEnv = {
      ...defaultGradebookProps.gradebookEnv,
      custom_grade_statuses_enabled: true,
    }
    const {queryByTestId} = render(
      <Gradebook
        {...defaultGradebookProps}
        isSubmissionDataLoaded={true}
        totalSubmissionsLoaded={0}
        totalStudentsToLoad={11}
        gradebookEnv={gradeBookEnv}
      />
    )

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(queryByTestId('total-grade-override-tray')).toBeInTheDocument()
  })

  it('should not render the total grade override tray with FF OFF', async () => {
    store.setState({
      finalGradeOverrideTrayProps: {
        isTrayOpen: true,
        studentInfo: {id: '1', name: 'Test Student'},
      },
    })
    const gradeBookEnv = {
      ...defaultGradebookProps.gradebookEnv,
      custom_grade_statuses_enabled: false,
    }
    const {queryByTestId} = render(
      <Gradebook
        {...defaultGradebookProps}
        isSubmissionDataLoaded={true}
        totalSubmissionsLoaded={0}
        totalStudentsToLoad={11}
        gradebookEnv={gradeBookEnv}
      />
    )

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(queryByTestId('total-grade-override-tray')).not.toBeInTheDocument()
  })
})
