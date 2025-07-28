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

import {render, act, waitFor, fireEvent} from '@testing-library/react'
import React from 'react'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {Assignment} from '../../../../graphql/Assignment'
import DiscussionTopicForm from '../DiscussionTopicForm'
import {useAssetProcessorsState} from '@canvas/lti-asset-processor/react/hooks/AssetProcessorsState'
import {useAssetProcessorsToolsList} from '@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList'
import {
  mockTools,
  mockDeepLinkResponse,
  mockAssetProcessorsToolsListQuery,
} from '../../../../../../shared/lti-asset-processor/react/__tests__/assetProcessorsTestHelpers'

jest.mock('@canvas/rce/react/CanvasRce')
// Without mocking useAssetProcessorsToolsList, the request will fail / never
// come back by default, which is OK for many Discussions tests, but obviously
// not for this one where we test the AssetProcessors integration.
jest.mock('@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList')

describe('DiscussionTopicForm', () => {
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
  })

  beforeEach(() => {
    ;(useAssetProcessorsToolsList as any).mockReturnValue(mockAssetProcessorsToolsListQuery)
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  describe('AssetProcessors Integration', () => {
    it('renders without AssetProcessors section when discussion is not graded', () => {
      const {queryByText} = setup({isEditing: false})
      expect(queryByText('Document Processing App(s)')).not.toBeInTheDocument()
    })

    it('shows AssetProcessors section when switching to graded', () => {
      const {getByLabelText, queryByText} = setup({
        isEditing: false,
      })
      act(() => {
        getByLabelText('Graded').click()
      })
      expect(queryByText('Document Processing App(s)')).toBeInTheDocument()
    })

    it('can add existing asset processors from GraphQL to the store', async () => {
      const assignment = Assignment.mock()
      // @ts-expect-error
      const mockDiscussionTopic = DiscussionTopic.mock({assignment})

      const {queryByText} = setup({
        isEditing: true,
        currentDiscussionTopic: mockDiscussionTopic,
      })

      expect(queryByText('Document Processing App(s)')).toBeInTheDocument()

      const aps = useAssetProcessorsState.getState().attachedProcessors
      expect(aps).toHaveLength(1)
      expect(aps[0].text).toBe('This is a mock LTI Asset Processor')
      expect(aps[0].toolName).toBe('Mock Tool')

      expect(queryByText('This is a mock LTI Asset Processor')).toBeInTheDocument()
    })

    it('saves both existing and added processors when editing a DiscussionTopic', async () => {
      const assignment = Assignment.mock()
      // @ts-expect-error
      const mockDiscussionTopic = DiscussionTopic.mock({assignment})
      const mockOnSubmit = jest.fn()

      const {getByRole} = setup({
        isEditing: true,
        currentDiscussionTopic: mockDiscussionTopic,
        onSubmit: mockOnSubmit,
      })

      act(() => {
        useAssetProcessorsState.getState().addAttachedProcessors({
          tool: mockTools[0],
          data: mockDeepLinkResponse,
        })
      })

      expect(useAssetProcessorsState.getState().attachedProcessors).toHaveLength(2)

      getByRole('button', {name: 'Save'}).click()

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
            contextExternalToolId: parseInt(mockTools[0].definition_id),
            // from mockDeepLinkResponse:
            text: 'Lti 1.3 Tool Text',
            title: 'Lti 1.3 Tool Title',
            report: {},
          },
        },
      ])
    })

    it('adds a new discussion topic with AssetProcessors', async () => {
      const mockOnSubmit = jest.fn()
      const {getByRole, getByLabelText, getByPlaceholderText} = setup({
        isEditing: false,
        onSubmit: mockOnSubmit,
      })

      fireEvent.input(getByPlaceholderText('Topic Title'), {target: {value: 'a title'}})

      // Switch to graded
      getByLabelText('Graded').click()

      act(() => {
        useAssetProcessorsState.getState().addAttachedProcessors({
          tool: mockTools[0],
          data: mockDeepLinkResponse,
        })
      })

      expect(useAssetProcessorsState.getState().attachedProcessors).toHaveLength(1)
      getByRole('button', {name: 'Save'}).click()

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalled()
      })

      const submissionData = mockOnSubmit.mock.calls[0][0]
      // For expected structure, see AttachedAssetProcessorGraphqlMutation
      const aps = submissionData.assignment.assetProcessors
      expect(aps).toEqual([
        {
          newContentItem: {
            contextExternalToolId: parseInt(mockTools[0].definition_id),
            // from mockDeepLinkResponse:
            text: 'Lti 1.3 Tool Text',
            title: 'Lti 1.3 Tool Title',
            report: {},
          },
        },
      ])
    })
  })
})
