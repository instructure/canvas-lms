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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {PublishButton} from '../PublishButton'

const setup = props => {
  return render(<PublishButton initialState="published" onClick={Function.prototype} {...props} />)
}

describe('PublishButton', () => {
  it('renders with the correct display text', () => {
    const {queryByText, rerender} = setup()
    expect(queryByText('Published')).toBeTruthy()
    expect(queryByText('Publish')).toBeFalsy()

    rerender(
      <PublishButton key="unpublished" initialState="unpublished" onClick={Function.prototype} />
    )
    expect(queryByText('Published')).toBeFalsy()
    expect(queryByText('Publish')).toBeTruthy()
  })

  describe('interactive state', () => {
    it('enters interactive state when hovered in previously published', () => {
      const {queryByText, getByText} = setup()
      expect(queryByText('Published')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()

      const button = getByText('Published')
      fireEvent.mouseOver(button)
      expect(queryByText('Published')).toBeFalsy()
      expect(queryByText('Unpublish')).toBeTruthy()

      fireEvent.mouseOut(button)
      expect(queryByText('Published')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()
    })

    it('does not enter interactive state for other statuses when hovered', () => {
      const {queryByText, getByText} = setup({initialState: 'unpublished'})
      expect(queryByText('Publish')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()

      const button = getByText('Publish')
      fireEvent.mouseOver(button)
      expect(queryByText('Publish')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()
    })

    it('enters interactive state when focused in previously published', () => {
      const {queryByText, getByText} = setup()
      expect(queryByText('Published')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()

      const button = getByText('Published')
      fireEvent.focus(button)
      expect(queryByText('Published')).toBeFalsy()
      expect(queryByText('Unpublish')).toBeTruthy()

      fireEvent.blur(button)
      expect(queryByText('Published')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()
    })

    it('does not enter interactive state for other statuses when focused', () => {
      const {queryByText, getByText} = setup({initialState: 'unpublished'})
      expect(queryByText('Publish')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()

      const button = getByText('Publish')
      fireEvent.focus(button)
      expect(queryByText('Publish')).toBeTruthy()
      expect(queryByText('Unpublish')).toBeFalsy()
    })
  })

  describe('handling clicks', () => {
    it('calls provided callback when clicked', () => {
      const onClickMock = jest.fn()
      const {getByText} = setup({onClick: onClickMock})
      expect(onClickMock.mock.calls.length).toBe(0)
      fireEvent.click(getByText('Published'))
      expect(onClickMock.mock.calls.length).toBe(1)
    })

    it('does not trigger callback for loading states', () => {
      const onClickMock = jest.fn()
      const {getByText} = setup({
        onClick: onClickMock,
        initialState: 'publishing'
      })
      expect(onClickMock.mock.calls.length).toBe(0)
      fireEvent.click(getByText('Publishing...'))
      expect(onClickMock.mock.calls.length).toBe(0)
    })
  })
})
