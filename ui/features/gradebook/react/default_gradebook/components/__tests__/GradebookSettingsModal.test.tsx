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
import fetchMock from 'fetch-mock'
import {render} from '@testing-library/react'
import userEvent, {type UserEvent} from '@testing-library/user-event'
import {statusColors} from '../../constants/colors'
import type {GradebookViewOptions, LatePolicy} from '../../gradebook.d'
import {DEFAULT_LATE_POLICY_DATA} from '../../apis/GradebookSettingsModalApi'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

describe('GradebookSettingsModal', () => {
  let props: GradebookSettingsModalProps
  let user: UserEvent
  let latePolicyUrl: string

  beforeEach(() => {
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
    })

    props = {
      anonymousAssignmentsPresent: false,
      courseFeatures: {finalGradeOverrideEnabled: false},
      courseId: '1',
      courseSettings: {allowFinalGradeOverride: false},
      locale: 'en',
      onRequestClose: jest.fn(),
      onAfterClose: jest.fn(),
      gradebookIsEditable: true,
      gradedLateSubmissionsExist: false,
      loadCurrentViewOptions,
      onCourseSettingsUpdated: jest.fn(),
      onLatePolicyUpdate: jest.fn(),
      onViewOptionsUpdated: jest.fn().mockResolvedValue([]),
      open: true,
      postPolicies: {
        coursePostPolicy: {postManually: false},
        setAssignmentPostPolicies: jest.fn(),
        setCoursePostPolicy: jest.fn(),
      },
    }

    latePolicyUrl = `/api/v1/courses/${props.courseId}/late_policy`
    // If a course hasn't yet created a late policy, this returns a 404 and the front-end handles it.
    fetchMock.get(latePolicyUrl, 404)
  })

  afterEach(() => {
    destroyContainer()
    fetchMock.restore()
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

  describe('"Late Policies" tab', () => {
    let response: {late_policy: LatePolicy}

    beforeEach(() => {
      response = {
        late_policy: {
          missing_submission_deduction_enabled: true,
          missing_submission_deduction: 75,
          late_submission_deduction_enabled: false,
          late_submission_deduction: 0,
          late_submission_interval: 'day',
          late_submission_minimum_percent_enabled: false,
          late_submission_minimum_percent: 0,
        },
      }
    })

    it('creates a late policy when "Apply Settings" is clicked and then closes the modal, if no late policy exists', async () => {
      const createPolicyStub = fetchMock.postOnce(latePolicyUrl, response)
      const {findByTestId, findByLabelText, getByTestId} = render(
        <GradebookSettingsModal {...props} />,
      )

      const updateButton = getByTestId('gradebook-settings-update-button')
      expect(updateButton).toBeDisabled()

      const input = await findByTestId('missing-submission-grade')
      expect(input).toBeDisabled()

      const checkbox = await findByLabelText('Automatically apply grade for missing submissions')
      await user.click(checkbox)
      expect(input).toBeEnabled()
      expect(updateButton).toBeEnabled()

      await user.clear(input)
      await user.type(input, '25')

      expect(updateButton).toBeEnabled()
      await user.click(updateButton)

      const body = createPolicyStub.lastOptions()?.body
      expect(body).toEqual(
        JSON.stringify({
          late_policy: {
            missing_submission_deduction_enabled: true,
            missing_submission_deduction: 75,
          },
        }),
      )

      expect(props.onRequestClose).toHaveBeenCalled()
    })

    it('updates the late policy when "Apply Settings" is clicked and then closes the modal, if a late policy exists', async () => {
      fetchMock.get(
        latePolicyUrl,
        {
          late_policy: {...DEFAULT_LATE_POLICY_DATA, id: '8', newRecord: false},
        },
        {overwriteRoutes: true},
      )

      const updatePolicyStub = fetchMock.patchOnce(latePolicyUrl, 204)
      const {findByTestId, findByLabelText, getByTestId} = render(
        <GradebookSettingsModal {...props} />,
      )

      const updateButton = getByTestId('gradebook-settings-update-button')
      expect(updateButton).toBeDisabled()

      const input = await findByTestId('missing-submission-grade')
      expect(input).toBeDisabled()

      const checkbox = await findByLabelText('Automatically apply grade for missing submissions')
      await user.click(checkbox)
      expect(input).toBeEnabled()
      expect(updateButton).toBeEnabled()

      await user.clear(input)
      await user.type(input, '25')

      expect(updateButton).toBeEnabled()
      await user.click(updateButton)

      const body = updatePolicyStub.lastOptions()?.body
      expect(body).toEqual(
        JSON.stringify({
          late_policy: {
            missing_submission_deduction_enabled: true,
            missing_submission_deduction: 75,
          },
        }),
      )

      expect(props.onRequestClose).toHaveBeenCalled()
    })
  })

  describe('"Grade Posting Policy" tab', () => {
    it('updates the course post policy when "Apply Settings" is clicked and then closes the modal', async () => {
      const gqlStub = fetchMock
        .post(
          (url, opts) => {
            const body = JSON.parse(opts.body as string)
            return url === '/api/graphql' && body.operationName === 'SetCoursePostPolicy'
          },
          {
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
          },
          {name: 'setCoursePolicy'},
        )
        .post(
          (url, opts) => {
            const body = JSON.parse(opts.body as string)
            return url === '/api/graphql' && body.operationName === 'CourseAssignmentPostPolicies'
          },
          {
            data: {
              course: {
                assignmentsConnection: {nodes: [], __typename: 'AssignmentConnection'},
                __typename: 'Course',
              },
            },
          },
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
      const body = JSON.parse(gqlStub.lastCall('setCoursePolicy')?.[1]?.body as string)
      expect(body.variables.postManually).toEqual(true)

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

      const updateSettingsStub = fetchMock.put(
        `/api/v1/courses/${props.courseId}/settings`,
        settingsResponse,
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
      const body = JSON.parse(updateSettingsStub.lastCall()?.[1]?.body as string)
      expect(body.allow_final_grade_override).toEqual(true)

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
