/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm Publish and Settings', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    setupDefaultEnv()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('assignment edit placement', () => {
    it('renders if the discussion is not an announcement', () => {
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).toBeInTheDocument()
    })

    it('renders if it is an announcement and the assignment edit placement not on announcements FF is off', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        is_announcement: true,
      }
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).toBeInTheDocument()
    })

    it('does not render if it is an announcement and the assignment edit placement not on announcements FF is on', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        is_announcement: true,
      }
      window.ENV.ASSIGNMENT_EDIT_PLACEMENT_NOT_ON_ANNOUNCEMENTS = true
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).not.toBeInTheDocument()
    })

    it('does not render if the context is not a course', () => {
      ENV.context_is_not_group = false
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).not.toBeInTheDocument()
    })
  })

  describe('publish indicator', () => {
    it('does not show the publish indicator when editing an announcement', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        id: 88,
        is_announcement: true,
        course_published: false,
      }

      const {queryByText} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })

      // Verifies that the publish indicator is not in the document
      expect(queryByText('Published')).not.toBeInTheDocument()
      expect(queryByText('Not Published')).not.toBeInTheDocument()
    })

    it('displays the publish indicator with the text `Not Published` when not editing', () => {
      const {queryByText} = setup({isEditing: false})

      // Verifies that the publish indicator with the text Not Published is in the document
      expect(queryByText('Not Published')).toBeInTheDocument()
    })

    it('displays publish indicator correctly', () => {
      const {getByText} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: true}),
      })

      // Verifies that the publish indicator displays "Published"
      expect(getByText('Published')).toBeInTheDocument()
    })

    it('displays unpublished indicator correctly', () => {
      const {getByText} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })

      // Verifies that the publish indicator displays "Not Published"
      expect(getByText('Not Published')).toBeInTheDocument()
    })
  })

  describe('view settings', () => {
    it('renders view settings, if the discussion is not announcement', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
      const {queryByTestId} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })
      expect(queryByTestId('discussion-view-settings')).toBeInTheDocument()
    })

    it('does not render view settings, if the discussion is announcement', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      const {queryByTestId} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })
      expect(queryByTestId('discussion-view-settings')).not.toBeInTheDocument()
    })
  })
})
