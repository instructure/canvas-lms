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
import type {GradebookViewOptions, LatePolicy} from '../../gradebook.d'
import {DEFAULT_LATE_POLICY_DATA} from '../../apis/GradebookSettingsModalApi'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const server = setupServer()

describe('GradebookSettingsModal Late Policies', () => {
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

  it('creates a late policy when "Apply Settings" is clicked and then closes the modal, if no late policy exists', async () => {
    const response: {late_policy: LatePolicy} = {
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

    let capturedBody: any
    server.use(
      http.post(latePolicyUrl, async ({request}) => {
        capturedBody = await request.json()
        return HttpResponse.json(response)
      }),
    )

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

    expect(capturedBody).toEqual({
      late_policy: {
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 75,
      },
    })

    expect(props.onRequestClose).toHaveBeenCalled()
  })

  it('updates the late policy when "Apply Settings" is clicked and then closes the modal, if a late policy exists', async () => {
    const response: {late_policy: LatePolicy} = {
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

    let capturedBody: any
    server.use(
      http.get(latePolicyUrl, () => {
        return HttpResponse.json({
          late_policy: {...DEFAULT_LATE_POLICY_DATA, id: '8', newRecord: false},
        })
      }),
      http.patch(latePolicyUrl, async ({request}) => {
        capturedBody = await request.json()
        return new HttpResponse(null, {status: 204})
      }),
    )

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

    expect(capturedBody).toEqual({
      late_policy: {
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 75,
      },
    })

    expect(props.onRequestClose).toHaveBeenCalled()
  })
})
