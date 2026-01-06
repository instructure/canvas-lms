/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, act, waitFor} from '@testing-library/react'
import React from 'react'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {Assignment} from '../../../../graphql/Assignment'
import DiscussionTopicForm from '../DiscussionTopicForm'
import {useAssetProcessorsState} from '@canvas/lti-asset-processor/react/hooks/AssetProcessorsState'
import {useAssetProcessorsToolsList} from '@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList'
import {
  mockToolsForDiscussions,
  mockContributionDeepLinkResponse,
  mockAssetProcessorsToolsListQuery,
} from '../../../../../../shared/lti-asset-processor/react/__tests__/assetProcessorsTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')
vi.mock('@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList')

describe('DiscussionTopicForm AssetProcessors Submission', () => {
  const setup = ({isEditing = true, currentDiscussionTopic = {}, onSubmit = () => {}} = {}) => {
    return render(
      <DiscussionTopicForm
        assignmentGroups={[]}
        isEditing={isEditing}
        currentDiscussionTopic={currentDiscussionTopic}
        isStudent={false}
        sections={[]}
        groupCategories={[]}
        onSubmit={onSubmit}
        apolloClient={null}
        studentEnrollments={[]}
        isGroupContext={false}
        isSubmitting={false}
        setIsSubmitting={() => {}}
        breakpoints={{}}
      />,
    )
  }

  beforeEach(() => {
    window.ENV = {
      DISCUSSION_TOPIC: {
        // @ts-expect-error
        PERMISSIONS: {
          CAN_ATTACH: true,
          CAN_MODERATE: true,
          CAN_CREATE_ASSIGNMENT: true,
          CAN_SET_GROUP: true,
          CAN_MANAGE_ASSIGN_TO_GRADED: true,
          CAN_MANAGE_ASSIGN_TO_UNGRADED: true,
        },
        ATTRIBUTES: {},
      },
      FEATURES: {
        lti_asset_processor_discussions: true,
        lti_asset_processor_course: true,
      },
      // @ts-expect-error
      PERMISSIONS: {},
      // @ts-expect-error
      SETTINGS: {},
      allow_student_anonymous_discussion_topics: false,
      USAGE_RIGHTS_REQUIRED: false,
      K5_HOMEROOM_COURSE: 'false',
      STUDENT_PLANNER_ENABLED: true,
      DISCUSSION_CHECKPOINTS_ENABLED: true,
      ASSIGNMENT_EDIT_PLACEMENT_NOT_ON_ANNOUNCEMENTS: false,
      context_is_not_group: true,
      RESTRICT_QUANTITATIVE_DATA: false,
    }

    ;(useAssetProcessorsToolsList as any).mockReturnValue(mockAssetProcessorsToolsListQuery)

    // Reset attached processors after mocks are set up
    useAssetProcessorsState.setState({attachedProcessors: []})
  })

  afterEach(() => {
    vi.resetAllMocks()
  })

  it('saves both existing and added processors when editing a DiscussionTopic', async () => {
    const assignment = Assignment.mock()
    // @ts-expect-error
    const mockDiscussionTopic = DiscussionTopic.mock({assignment})
    const mockOnSubmit = vi.fn()

    const {getByTestId} = setup({
      isEditing: true,
      currentDiscussionTopic: mockDiscussionTopic,
      onSubmit: mockOnSubmit,
    })

    act(() => {
      useAssetProcessorsState.getState().addAttachedProcessors({
        tool: mockToolsForDiscussions[0],
        data: mockContributionDeepLinkResponse,
        type: 'ActivityAssetProcessorContribution',
      })
    })

    expect(useAssetProcessorsState.getState().attachedProcessors).toHaveLength(2)

    await act(async () => {
      getByTestId('save-button').click()
    })

    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalled()
    })

    const submissionData = mockOnSubmit.mock.calls[0][0]
    // For expected structure, see AttachedAssetProcessorGraphqlMutation
    const aps = submissionData.assignment.assetProcessors
    expect(aps).toEqual([
      {existingId: 1},
      {
        newContentItem: {
          contextExternalToolId: parseInt(mockToolsForDiscussions[0].definition_id),
          // from mockDeepLinkResponse:
          text: 'Lti 1.3 Tool Text',
          title: 'Lti 1.3 Tool Title',
          report: {},
        },
      },
    ])
  })
})
