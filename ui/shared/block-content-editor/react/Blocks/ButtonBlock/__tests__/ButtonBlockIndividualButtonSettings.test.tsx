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

const createButton = (id: number, options: Partial<ButtonData> = {}): ButtonData => ({
  id,
  text: '',
  url: '',
  linkOpenMode: 'new-tab',
  ...options,
})

const defaultProps: ButtonBlockIndividualButtonSettingsProps = {
  initialButtons: [createButton(1, {text: 'Button 1'}), createButton(2, {text: 'Button 2'})],
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
        createButton(1, {text: 'Button 1'}),
        createButton(2, {text: 'Button 2'}),
        createButton(3),
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
      expect(buttonsChanged).toHaveBeenCalledWith([createButton(2, {text: 'Button 2'})])
    })

    describe('focus after delete', () => {
      const renderFocusTest = (onButtonsChange = jest.fn()) => {
        const propsWithThreeButtons = {
          ...defaultProps,
          initialButtons: [
            createButton(1, {text: 'Button 1'}),
            createButton(2, {text: 'Button 2'}),
            createButton(3, {text: 'Button 3'}),
          ],
          onButtonsChange,
        }
        render(<ButtonBlockIndividualButtonSettings {...propsWithThreeButtons} />)
        return onButtonsChange
      }

      const deleteButton = (buttonId: number) => {
        act(() => {
          fireEvent.click(screen.getByTestId(`button-settings-delete-${buttonId}`))
        })
      }

      const expectToggleToHaveFocus = (buttonId: number) => {
        const toggle = screen.getByTestId(`button-settings-toggle-${buttonId}`)
        expect(toggle.querySelector('button')).toHaveFocus()
      }

      it('focuses on the button above after deleting a button', () => {
        renderFocusTest()
        deleteButton(2)
        expectToggleToHaveFocus(1)
      })

      it('focuses on the next button after deleting the first button', () => {
        renderFocusTest()
        deleteButton(1)
        expectToggleToHaveFocus(2)
      })
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
        createButton(1, {text: 'Updated Button 1'}),
        createButton(2, {text: 'Button 2'}),
      ])
    })

    it('updates button url', () => {
      const buttonsChanged = jest.fn()
      render(
        <ButtonBlockIndividualButtonSettings {...defaultProps} onButtonsChange={buttonsChanged} />,
      )

      clickToggleButton(1)
      const buttonUrlInput = screen.getByRole('textbox', {name: /url/i})
      act(() => {
        fireEvent.change(buttonUrlInput, {target: {value: 'https://example.com'}})
      })

      expect(buttonsChanged).toHaveBeenCalledWith([
        createButton(1, {text: 'Button 1', url: 'https://example.com'}),
        createButton(2, {text: 'Button 2'}),
      ])
    })

    it('updates button linkOpenMode', () => {
      const buttonsChanged = jest.fn()
      render(
        <ButtonBlockIndividualButtonSettings {...defaultProps} onButtonsChange={buttonsChanged} />,
      )

      clickToggleButton(1)

      fireEvent.click(screen.getByLabelText(/how to open link/i))
      fireEvent.click(screen.getByText(/open in the current tab/i))

      expect(buttonsChanged).toHaveBeenCalledWith([
        createButton(1, {text: 'Button 1', linkOpenMode: 'same-tab'}),
        createButton(2, {text: 'Button 2'}),
      ])
    })
  })
})
