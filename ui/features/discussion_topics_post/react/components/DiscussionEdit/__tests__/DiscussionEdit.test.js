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
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {DiscussionEdit} from '../DiscussionEdit'
import {render, fireEvent} from '@testing-library/react'

const setup = props => {
  return render(<DiscussionEdit {...props} />)
}

const defaultProps = ({
  show = undefined,
  value = undefined,
  onCancel = jest.fn(),
  onSubmit = jest.fn()
} = {}) => ({
  show,
  value,
  onCancel,
  onSubmit
})

describe('DiscussionEdit', () => {
  beforeEach(() => {
    RichContentEditor.loadNewEditor = jest.fn()
    RichContentEditor.callOnRCE = jest.fn()
    RichContentEditor.closeRCE = jest.fn()
    RichContentEditor.destroyRCE = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
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

    it('should fire obSubmit when clicked', () => {
      const onSubmitMock = jest.fn()
      const {getByTestId} = setup(defaultProps({onSubmit: onSubmitMock}))
      const submitButton = getByTestId('DiscussionEdit-submit')
      fireEvent.click(submitButton)
      expect(onSubmitMock.mock.calls.length).toBe(1)
    })
  })
})
