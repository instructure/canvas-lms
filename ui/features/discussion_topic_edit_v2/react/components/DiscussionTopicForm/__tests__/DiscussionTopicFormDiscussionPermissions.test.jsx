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

import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm Discussion Permissions', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    setupDefaultEnv()
    window.ENV.allow_student_anonymous_discussion_topics = true
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('CAN_EDIT_DISCUSSION_ANONYMITY', () => {
    it('enables anonymous selector when permission is true', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_ANONYMITY = true
      const {queryByTestId} = setup()
      const selector = queryByTestId('anonymous-discussion-options')
      expect(selector).toBeInTheDocument()
      // The selector should not be disabled
      const select = selector?.querySelector('select')
      if (select) expect(select).not.toBeDisabled()
    })

    it('disables anonymous selector when permission is false', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_ANONYMITY = false
      const {queryByTestId} = setup()
      const selector = queryByTestId('anonymous-discussion-options')
      expect(selector).toBeInTheDocument()
      // The selector should be disabled
      const select = selector?.querySelector('select')
      if (select) expect(select).toBeDisabled()
    })
  })

  describe('CAN_EDIT_DISCUSSION_OPTIONS', () => {
    it('enables options checkboxes when permission is true', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_OPTIONS = true
      const {queryByTestId} = setup()
      const requireInitialPost = queryByTestId('require-initial-post-checkbox')
      expect(requireInitialPost).toBeInTheDocument()
      expect(requireInitialPost?.querySelector('input[type="checkbox"]')).not.toBeDisabled()
    })

    it('disables options checkboxes when permission is false', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_OPTIONS = false
      const {queryByTestId} = setup()
      const requireInitialPost = queryByTestId('require-initial-post-checkbox')
      expect(requireInitialPost).toBeInTheDocument()
      expect(requireInitialPost?.querySelector('input[type="checkbox"]')).toBeDisabled()
    })

    it('disables podcast feed checkbox when permission is false', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_OPTIONS = false
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.allow_student_anonymous_discussion_topics = false
      const {queryByTestId} = setup()
      const podcastCheckbox = queryByTestId('enable-podcast-checkbox')
      expect(podcastCheckbox).toBeInTheDocument()
      expect(podcastCheckbox?.querySelector('input[type="checkbox"]')).toBeDisabled()
    })

    it('disables liking checkbox when permission is false', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_OPTIONS = false
      const {queryByTestId} = setup()
      const likeCheckbox = queryByTestId('like-checkbox')
      expect(likeCheckbox).toBeInTheDocument()
      expect(likeCheckbox?.querySelector('input[type="checkbox"]')).toBeDisabled()
    })
  })

  describe('CAN_EDIT_DISCUSSION_VIEWS', () => {
    it('enables view settings when permission is true', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_VIEWS = true
      const {queryByTestId} = setup()
      const viewSettings = queryByTestId('discussion-view-settings')
      expect(viewSettings).toBeInTheDocument()
    })

    it('disables view settings when permission is false', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_VIEWS = false
      const {queryByTestId} = setup()
      const viewSettings = queryByTestId('discussion-view-settings')
      expect(viewSettings).toBeInTheDocument()
      // All radio inputs within view settings should be disabled
      const inputs = viewSettings?.querySelectorAll('input')
      inputs?.forEach(input => {
        expect(input).toBeDisabled()
      })
    })
  })

  describe('permissions are independent', () => {
    it('disabling anonymity does not disable options', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_ANONYMITY = false
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_OPTIONS = true
      const {queryByTestId} = setup()
      const requireInitialPost = queryByTestId('require-initial-post-checkbox')
      expect(requireInitialPost?.querySelector('input[type="checkbox"]')).not.toBeDisabled()
    })

    it('disabling options does not disable views', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_OPTIONS = false
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_EDIT_DISCUSSION_VIEWS = true
      const {queryByTestId} = setup()
      // View settings should not be disabled
      const viewSettings = queryByTestId('discussion-view-settings')
      expect(viewSettings).toBeInTheDocument()
      const inputs = viewSettings?.querySelectorAll('input')
      inputs?.forEach(input => {
        expect(input).not.toBeDisabled()
      })
    })
  })
})
