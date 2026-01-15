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

import React from 'react'
import GradebookSettingsModal, {type GradebookSettingsModalProps} from '../GradebookSettingsModal'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {render} from '@testing-library/react'
import userEvent, {type UserEvent} from '@testing-library/user-event'
import {statusColors} from '../../constants/colors'
import type {GradebookViewOptions} from '../../gradebook.d'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const server = setupServer()

describe('GradebookSettingsModal', () => {
  let props: GradebookSettingsModalProps
  let user: UserEvent
  let latePolicyUrl: string

  beforeEach(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    user = userEvent.setup()

    const loadCurrentViewOptions = (): GradebookViewOptions => ({
      columnSortSettings: {criterion: 'default', direction: 'ascending'},
      hideTotal: false,
      showNotes: false,
      showSeparateFirstLastNames: false,
      showUnpublishedAssignments: false,
      hideAssignmentGroupTotals: false,
      statusColors: statusColors(),
      viewUngradedAsZero: false,
      viewHiddenGradesIndicator: false,
      viewStatusForColorblindness: false,
    })

    props = {
      anonymousAssignmentsPresent: false,
      courseFeatures: {finalGradeOverrideEnabled: false},
      courseId: '1',
      courseSettings: {allowFinalGradeOverride: false},
      locale: 'en',
      onRequestClose: vi.fn(),
      onAfterClose: vi.fn(),
      gradebookIsEditable: true,
      gradedLateSubmissionsExist: false,
      loadCurrentViewOptions,
      onCourseSettingsUpdated: vi.fn(),
      onLatePolicyUpdate: vi.fn(),
      onViewOptionsUpdated: vi.fn().mockResolvedValue([]),
      open: true,
      postPolicies: {
        coursePostPolicy: {postManually: false},
        setAssignmentPostPolicies: vi.fn(),
        setCoursePostPolicy: vi.fn(),
      },
    }

    latePolicyUrl = `/api/v1/courses/${props.courseId}/late_policy`
    // If a course hasn't yet created a late policy, this returns a 404 and the front-end handles it.
    server.use(http.get(latePolicyUrl, () => new HttpResponse(null, {status: 404})))
  })

  afterEach(() => {
    destroyContainer()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('opening the modal', () => {
    it('opens the modal when passed open: true', () => {
      const {getByText} = render(<GradebookSettingsModal {...props} />)
      const title = getByText('Gradebook Settings', {selector: 'h3'})
      expect(title).toBeInTheDocument()
    })

    it('loads default late policy data and shows the Late Policies tab by default', async () => {
      const {findByTestId} = render(<GradebookSettingsModal {...props} />)
      const input = await findByTestId('missing-submission-grade')
      expect(input).toHaveValue('0')
    })
  })

  describe('closing the modal', () => {
    it('closes the modal when passed open: false', () => {
      props.open = false
      const {queryByText} = render(<GradebookSettingsModal {...props} />)
      const title = queryByText('Gradebook Settings', {selector: 'h3'})
      expect(title).not.toBeInTheDocument()
    })
  })

  describe('"Grade Posting Policy" tab', () => {
    it('updates the course post policy when "Apply Settings" is clicked and then closes the modal', async () => {
      let setCoursePostPolicyBody: any
      server.use(
        http.post('/api/graphql', async ({request}) => {
          const body: any = await request.json()
          if (body.operationName === 'SetCoursePostPolicy') {
            setCoursePostPolicyBody = body
            return HttpResponse.json({
              data: {
                setCoursePostPolicy: {
                  postPolicy: {
                    postManually: true,
                    __typename: 'PostPolicy',
                  },
                  errors: null,
                  __typename: 'SetCoursePostPolicyPayload',
                },
              },
            })
          } else if (body.operationName === 'CourseAssignmentPostPolicies') {
            return HttpResponse.json({
              data: {
                course: {
                  assignmentsConnection: {nodes: [], __typename: 'AssignmentConnection'},
                  __typename: 'Course',
                },
              },
            })
          }
          return new HttpResponse(null, {status: 404})
        }),
      )

      const {findByText, findByTestId, getByTestId} = render(<GradebookSettingsModal {...props} />)

      const tab = await findByText('Grade Posting Policy')
      await user.click(tab)

      const postAutoCheckbox = await findByTestId('GradePostingPolicyTabPanel__PostAutomatically')
      expect(postAutoCheckbox).toBeChecked()

      const postManualCheckbox = await findByTestId('GradePostingPolicyTabPanel__PostManually')
      expect(postManualCheckbox).not.toBeChecked()

      const updateButton = getByTestId('gradebook-settings-update-button')
      expect(updateButton).toBeDisabled()

      await user.click(postManualCheckbox)
      expect(updateButton).toBeEnabled()

      await user.click(updateButton)
      expect(setCoursePostPolicyBody.variables.postManually).toEqual(true)

      expect(props.onRequestClose).toHaveBeenCalled()
    })
  })

  describe('"Advanced" tab', () => {
    it('hides the "Advanced" tab when the final grade override feature is disabled', async () => {
      const {queryByText} = render(<GradebookSettingsModal {...props} />)

      const tab = queryByText('Advanced')
      expect(tab).not.toBeInTheDocument()
    })

    it('updates the final grade override setting when "Apply Settings" is clicked and then closes the modal', async () => {
      const settingsResponse = {
        allow_final_grade_override: true,
        allow_student_discussion_topics: true,
        allow_student_forum_attachments: true,
        allow_student_discussion_editing: true,
        allow_student_discussion_reporting: true,
        allow_student_anonymous_discussion_topics: false,
        filter_speed_grader_by_student_group: false,
        grading_standard_enabled: true,
        grading_standard_id: '17',
        grade_passback_setting: null,
        allow_student_organized_groups: true,
        hide_final_grades: true,
        hide_distribution_graphs: false,
        hide_sections_on_course_users_page: false,
        lock_all_announcements: false,
        usage_rights_required: false,
        restrict_student_past_view: false,
        restrict_student_future_view: true,
        restrict_quantitative_data: false,
        show_announcements_on_home_page: false,
        home_page_announcement_limit: 3,
        syllabus_course_summary: true,
        homeroom_course: false,
        image_url: null,
        image_id: null,
        image: null,
        banner_image_url: null,
        banner_image_id: null,
        banner_image: null,
        course_color: null,
        friendly_name: null,
        default_due_time: '23:59:59',
        conditional_release: false,
      }

      let capturedSettings: any
      server.use(
        http.put(`/api/v1/courses/${props.courseId}/settings`, async ({request}) => {
          capturedSettings = await request.json()
          return HttpResponse.json(settingsResponse)
        }),
      )

      props.courseFeatures.finalGradeOverrideEnabled = true
      const {findByText, findByLabelText, getByTestId} = render(
        <GradebookSettingsModal {...props} />,
      )

      const tab = await findByText('Advanced')
      await user.click(tab)

      const gradeOverrideCheckbox = await findByLabelText('Allow final grade override')
      expect(gradeOverrideCheckbox).not.toBeChecked()

      const updateButton = getByTestId('gradebook-settings-update-button')
      expect(updateButton).toBeDisabled()

      await user.click(gradeOverrideCheckbox)
      expect(updateButton).toBeEnabled()

      await user.click(updateButton)
      expect(capturedSettings.allow_final_grade_override).toEqual(true)

      expect(props.onRequestClose).toHaveBeenCalled()
    })
  })

  describe('"View Options" tab', () => {
    it('updates view options when "Apply Settings" is clicked and then closes the modal', async () => {
      const {findByText, findByLabelText, getByTestId} = render(
        <GradebookSettingsModal {...props} />,
      )

      const tab = await findByText('View Options')
      await user.click(tab)

      const notesCheckbox = await findByLabelText('Notes')
      expect(notesCheckbox).not.toBeChecked()

      const updateButton = getByTestId('gradebook-settings-update-button')
      expect(updateButton).toBeDisabled()

      await user.click(notesCheckbox)
      expect(updateButton).toBeEnabled()

      await user.click(updateButton)
      expect(props.onViewOptionsUpdated).toHaveBeenCalledWith(
        expect.objectContaining({showNotes: true}),
      )

      expect(props.onRequestClose).toHaveBeenCalled()
    })
  })
})
