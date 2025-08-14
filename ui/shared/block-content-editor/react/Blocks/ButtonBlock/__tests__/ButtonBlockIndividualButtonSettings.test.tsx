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

import {render, screen, fireEvent, act} from '@testing-library/react'
import {ButtonBlockIndividualButtonSettings} from '../ButtonBlockIndividualButtonSettings'
import {ButtonData, ButtonBlockIndividualButtonSettingsProps} from '../types'

const createEmptyButton = (id: number, text: string = ''): ButtonData => ({
  id,
  text,
})

const defaultProps: ButtonBlockIndividualButtonSettingsProps = {
  initialButtons: [createEmptyButton(1, 'Button 1'), createEmptyButton(2, 'Button 2')],
  onButtonsChange: jest.fn(),
}

const clickToggleButton = (index: number) => {
  const wrapper = screen.getByTestId(`button-settings-toggle-${index}`)
  const button = wrapper.querySelector('button')
  act(() => {
    fireEvent.click(button!)
  })
}

describe('ButtonBlockIndividualButtonSettings', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders all button toggles', () => {
      render(<ButtonBlockIndividualButtonSettings {...defaultProps} />)

      expect(screen.getByTestId('button-settings-toggle-1')).toBeInTheDocument()
      expect(screen.getByTestId('button-settings-toggle-2')).toBeInTheDocument()
    })

    it('renders new button', () => {
      render(<ButtonBlockIndividualButtonSettings {...defaultProps} />)

      expect(screen.getByText('New button')).toBeInTheDocument()
    })
  })

  describe('button toggle', () => {
    it('toggle expands settings', () => {
      render(<ButtonBlockIndividualButtonSettings {...defaultProps} />)

      clickToggleButton(1)

      expect(screen.getByTestId('button-settings-1')).toBeVisible()
    })

    it('toggle collapses settings', () => {
      render(<ButtonBlockIndividualButtonSettings {...defaultProps} />)

      clickToggleButton(1)
      clickToggleButton(1)

      expect(screen.queryByTestId('button-settings-1')).not.toBeInTheDocument()
    })

    it('toggle collapses previously expanded button settings', () => {
      render(<ButtonBlockIndividualButtonSettings {...defaultProps} />)

      clickToggleButton(1)
      clickToggleButton(2)

      expect(screen.queryByTestId('button-settings-1')).not.toBeInTheDocument()
      expect(screen.getByTestId('button-settings-2')).toBeVisible()
    })
  })

  describe('Button actions', () => {
    it('adds a new button', () => {
      const buttonsChanged = jest.fn()
      render(
        <ButtonBlockIndividualButtonSettings {...defaultProps} onButtonsChange={buttonsChanged} />,
      )

      act(() => {
        fireEvent.click(screen.getByText('New button'))
      })

      expect(screen.getByTestId('button-settings-toggle-3')).toBeVisible()
      expect(buttonsChanged).toHaveBeenCalledWith([
        {id: 1, text: 'Button 1'},
        {id: 2, text: 'Button 2'},
        {id: 3, text: ''},
      ])
    })

    it('deletes a button', () => {
      const buttonsChanged = jest.fn()
      render(
        <ButtonBlockIndividualButtonSettings {...defaultProps} onButtonsChange={buttonsChanged} />,
      )

      act(() => {
        fireEvent.click(screen.getByTestId('button-settings-delete-1'))
      })

      expect(screen.queryByTestId('button-settings-toggle-1')).not.toBeInTheDocument()
      expect(buttonsChanged).toHaveBeenCalledWith([{id: 2, text: 'Button 2'}])
    })

    it('updates button text', () => {
      const buttonsChanged = jest.fn()
      render(
        <ButtonBlockIndividualButtonSettings {...defaultProps} onButtonsChange={buttonsChanged} />,
      )

      clickToggleButton(1)
      const buttonTextInput = screen.getByRole('textbox', {name: /button text/i})
      act(() => {
        fireEvent.change(buttonTextInput, {target: {value: 'Updated Button 1'}})
      })

      expect(buttonsChanged).toHaveBeenCalledWith([
        {id: 1, text: 'Updated Button 1'},
        {id: 2, text: 'Button 2'},
      ])
    })
  })
})
