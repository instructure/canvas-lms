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
  mockToolsForDiscussions,
  mockContributionDeepLinkResponse,
  mockAssetProcessorsToolsListQuery,
} from '../../../../../../shared/lti-asset-processor/react/__tests__/assetProcessorsTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')
// Without mocking useAssetProcessorsToolsList, the request will fail / never
// come back by default, which is OK for many Discussions tests, but obviously
// not for this one where we test the AssetProcessors integration.
vi.mock('@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList')

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
  })

  beforeEach(() => {
    ;(useAssetProcessorsToolsList as any).mockReturnValue(mockAssetProcessorsToolsListQuery)
  })

  afterEach(() => {
    vi.resetAllMocks()
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

    // TODO: vi->vitest - test times out waiting for async state, needs investigation
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

    // NOTE: Form submission tests moved to DiscussionTopicFormAssetProcessorsSubmission.test.tsx
    // to avoid CI timeout issues (these tests are slower due to form validation/submission)

    // TODO: vi->vitest - test times out, needs investigation
    it('does not show AssetProcessors section when lti_asset_processor_course is disabled', () => {
      window.ENV.FEATURES = {
        lti_asset_processor_discussions: true,
        lti_asset_processor_course: false,
      }
      const assignment = Assignment.mock()
      // @ts-expect-error
      const mockDiscussionTopic = DiscussionTopic.mock({assignment})
      const {queryByText} = setup({
        isEditing: true,
        currentDiscussionTopic: mockDiscussionTopic,
      })

      expect(queryByText('Document Processing App(s)')).not.toBeInTheDocument()
    })

    // TODO: vi->vitest - test has isolation issues, times out when run with other tests
    it('does not show AssetProcessors section when lti_asset_processor_discussions is disabled', () => {
      window.ENV.FEATURES = {
        lti_asset_processor_discussions: false,
        lti_asset_processor_course: true,
      }
      const assignment = Assignment.mock()
      // @ts-expect-error
      const mockDiscussionTopic = DiscussionTopic.mock({assignment})
      const {queryByText} = setup({
        isEditing: true,
        currentDiscussionTopic: mockDiscussionTopic,
      })

      expect(queryByText('Document Processing App(s)')).not.toBeInTheDocument()
    })

    // TODO: vi->vitest - test times out, needs investigation
    it('does not show AssetProcessors section when both feature flags are disabled', () => {
      window.ENV.FEATURES = {
        lti_asset_processor_discussions: false,
        lti_asset_processor_course: false,
      }
      const assignment = Assignment.mock()
      // @ts-expect-error
      const mockDiscussionTopic = DiscussionTopic.mock({assignment})
      const {queryByText} = setup({
        isEditing: true,
        currentDiscussionTopic: mockDiscussionTopic,
      })

      expect(queryByText('Document Processing App(s)')).not.toBeInTheDocument()
    })
  })
})
