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
import {DiscussionEdit} from '../DiscussionEdit'
import {render, fireEvent} from '@testing-library/react'
import $ from '@canvas/rails-flash-notifications'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()
jest.mock('@canvas/rce/react/CanvasRce')

const setup = props => {
  return render(<DiscussionEdit {...props} />)
}

const defaultProps = ({
  show = undefined,
  value = undefined,
  onCancel = jest.fn(),
  onSubmit = jest.fn(),
  isEdit = false,
  canReplyAnonymously = false,
  discussionAnonymousState = null,
  isAnnouncement = false,
} = {}) => ({
  show,
  value,
  isEdit,
  onCancel,
  onSubmit,
  canReplyAnonymously,
  discussionAnonymousState,
  isAnnouncement,
})

describe('DiscussionEdit', () => {
  const oldEnv = window.ENV

  afterEach(() => {
    window.ENV = oldEnv
  })

  describe('Rendering', () => {
    it('should render', () => {
      const component = setup(defaultProps())
      expect(component).toBeTruthy()
    })

    it('should not show when show is false', () => {
      const {getByTestId} = setup(defaultProps({show: false}))
      const container = getByTestId('DiscussionEdit-container')
      expect(container.style.display).toBe('none')
    })

    it('should show by default', () => {
      const {getByTestId} = setup(defaultProps())
      const container = getByTestId('DiscussionEdit-container')
      expect(container.style.display).toBe('')
    })
  })

  describe('Callbacks', () => {
    it('should fire onCancel when clicked', () => {
      const onCancelMock = jest.fn()
      const {getByTestId} = setup(defaultProps({onCancel: onCancelMock}))
      const cancelButton = getByTestId('DiscussionEdit-cancel')
      fireEvent.click(cancelButton)
      expect(onCancelMock.mock.calls.length).toBe(1)
    })

    it('should fire onSubmit when clicked', () => {
      const onSubmitMock = jest.fn()
      const {getByTestId} = setup(defaultProps({onSubmit: onSubmitMock}))
      const submitButton = getByTestId('DiscussionEdit-submit')
      fireEvent.click(submitButton)
      expect(onSubmitMock.mock.calls.length).toBe(1)
    })

    it('should trigger error on submit when value is too long', () => {
      const flashStub = jest.spyOn($, 'flashError')
      window.ENV.DISCUSSION_ENTRY_SIZE_LIMIT = 10
      const onSubmitMock = jest.fn()
      const {getByTestId} = setup(defaultProps({onSubmit: onSubmitMock, value: '<p>1234</p>'}))
      const submitButton = getByTestId('DiscussionEdit-submit')
      fireEvent.click(submitButton)
      expect(flashStub).toHaveBeenCalledWith(
        'The message size has exceeded the maximum text length.',
        2000
      )
      expect(onSubmitMock.mock.calls.length).toBe(0)
    })
  })

  describe('Anonymous Response Selector', () => {
    beforeEach(() => {
      ENV.current_user = {display_name: 'Ronald Weasley', avatar_image_url: ''}
    })

    describe('Topic is anonymous', () => {
      it('should render when can reply anonymously', () => {
        const container = setup(
          defaultProps({canReplyAnonymously: true, discussionAnonymousState: 'full_anonymity'})
        )
        expect(container.queryByTestId('anonymous-response-selector')).toBeTruthy()
      })

      it('should not render when cannot reply anonymously', () => {
        const container = setup(
          defaultProps({canReplyAnonymously: false, discussionAnonymousState: 'full_anonymity'})
        )
        expect(container.queryByTestId('anonymous-response-selector')).toBeNull()
      })
    })

    describe('Topic is not anonymous', () => {
      it('should not render when can reply anonymously', () => {
        const container = setup(defaultProps({canReplyAnonymously: false}))
        expect(container.queryByTestId('anonymous-response-selector')).toBeNull()
      })

      it('should not render when cannot reply anonymously', () => {
        const container = setup(defaultProps({canReplyAnonymously: false}))
        expect(container.queryByTestId('anonymous-response-selector')).toBeNull()
      })
    })

    describe('Editing a response', () => {
      it('should not show anonymous response selector', () => {
        const container = setup(
          defaultProps({
            canReplyAnonymously: true,
            discussionAnonymousState: 'partial_anonymity',
            isEdit: true,
          })
        )
        expect(container.queryByTestId('anonymous-response-selector')).toBeNull()
      })
    })
  })
})
