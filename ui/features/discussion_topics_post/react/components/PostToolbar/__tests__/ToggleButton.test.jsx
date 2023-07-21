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
import {ToggleButton} from '../ToggleButton'

const setup = props => {
  return render(
    <ToggleButton
      isEnabled={true}
      enabledIcon={<div data-testid="enabled-icon" />}
      disabledIcon={<div data-testid="disabled-icon" />}
      enabledTooltipText="enabled tooltip"
      disabledTooltipText="disabled tooltip"
      enabledScreenReaderLabel="enabled label"
      disabledScreenReaderLabel="disabled label"
      onClick={Function.prototype}
      {...props}
    />
  )
}

describe('ToggleButton', () => {
  describe('enabled', () => {
    it('renders as enabled', () => {
      const {queryByText, queryByTestId} = setup()
      expect(queryByTestId('enabled-icon')).toBeTruthy()
      expect(queryByTestId('disabled-icon')).toBeFalsy()
      expect(queryByText('enabled tooltip')).toBeTruthy()
      expect(queryByText('disabled tooltip')).toBeFalsy()
      expect(queryByText('enabled label')).toBeTruthy()
      expect(queryByText('disabled label')).toBeFalsy()
    })
  })

  describe('interaction', () => {
    it('renders as readonly', () => {
      const {queryByText, queryByTestId} = setup({interaction: 'readonly'})
      expect(queryByTestId('enabled-icon').closest('button').hasAttribute('disabled')).toBeTruthy()
      expect(queryByTestId('enabled-icon')).toBeTruthy()
      expect(queryByTestId('disabled-icon')).toBeFalsy()
      expect(queryByText('enabled tooltip')).toBeTruthy()
      expect(queryByText('disabled tooltip')).toBeFalsy()
      expect(queryByText('enabled label')).toBeTruthy()
      expect(queryByText('disabled label')).toBeFalsy()
    })
  })

  describe('disabled', () => {
    it('renders as disabled', () => {
      const {queryByText, queryByTestId} = setup({isEnabled: false})
      expect(queryByTestId('enabled-icon')).toBeFalsy()
      expect(queryByTestId('disabled-icon')).toBeTruthy()
      expect(queryByText('enabled tooltip')).toBeFalsy()
      expect(queryByText('disabled tooltip')).toBeTruthy()
      expect(queryByText('enabled label')).toBeFalsy()
      expect(queryByText('disabled label')).toBeTruthy()
    })
  })

  describe('handling clicks', () => {
    it('calls provided callback when clicked', () => {
      const onClickMock = jest.fn()
      const {getByText} = setup({onClick: onClickMock})
      expect(onClickMock.mock.calls.length).toBe(0)
      fireEvent.click(getByText('enabled label'))
      expect(onClickMock.mock.calls.length).toBe(1)
    })
  })
})
