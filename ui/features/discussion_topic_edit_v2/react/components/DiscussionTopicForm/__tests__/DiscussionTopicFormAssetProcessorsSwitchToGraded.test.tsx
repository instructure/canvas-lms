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

import {render, act} from '@testing-library/react'
import React from 'react'
import DiscussionTopicForm from '../DiscussionTopicForm'
import {useAssetProcessorsToolsList} from '@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList'
import {mockAssetProcessorsToolsListQuery} from '../../../../../../shared/lti-asset-processor/react/__tests__/assetProcessorsTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')
vi.mock('@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList')

/**
 * Test for AssetProcessors integration when switching to graded.
 * Split from DiscussionTopicForm6.test.tsx to avoid CI timeouts.
 */
describe('DiscussionTopicForm AssetProcessors - Switch to Graded', () => {
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
  })

  afterEach(() => {
    vi.resetAllMocks()
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
})
