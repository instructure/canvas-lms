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
import {userEvent} from '@testing-library/user-event'
import {ButtonBlockIndividualButtonSettings} from '../ButtonBlockIndividualButtonSettings'
import {ButtonBlockIndividualButtonSettingsProps} from '../types'
import {ButtonData} from '../../BlockItems/Button/types'

const createButton = (id: number, options: Partial<ButtonData> = {}): ButtonData => ({
  id,
  text: '',
  url: '',
  linkOpenMode: 'new-tab',
  primaryColor: '#000000',
  secondaryColor: '#FFFFFF',
  style: 'filled',
  ...options,
})

const defaultProps: ButtonBlockIndividualButtonSettingsProps = {
  backgroundColor: '#FFFFFF',
  initialButtons: [
    createButton(1, {
      text: 'Button 1',
    }),
    createButton(2, {
      text: 'Button 2',
    }),
  ],
  onButtonsChange: vi.fn(),
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
    vi.clearAllMocks()
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
      const buttonsChanged = vi.fn()
      render(
        <ButtonBlockIndividualButtonSettings {...defaultProps} onButtonsChange={buttonsChanged} />,
      )

      act(() => {
        fireEvent.click(screen.getByText('New button'))
      })

      expect(screen.getByTestId('button-settings-toggle-3')).toBeVisible()
      expect(buttonsChanged).toHaveBeenCalledWith([
        createButton(1, {
          text: 'Button 1',
        }),
        createButton(2, {
          text: 'Button 2',
        }),
        createButton(3, {
          text: '',
          primaryColor: '#2B7ABC',
          secondaryColor: '#FFFFFF',
        }),
      ])
    })

    it('deletes a button', () => {
      const buttonsChanged = vi.fn()
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
      const renderFocusTest = (onButtonsChange = vi.fn()) => {
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
      const buttonsChanged = vi.fn()
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

    describe('updates button color', () => {
      it('updates button background color', async () => {
        const buttonsChanged = vi.fn()
        const newColor = '#FF0000'
        render(
          <ButtonBlockIndividualButtonSettings
            {...defaultProps}
            onButtonsChange={buttonsChanged}
          />,
        )
        clickToggleButton(1)

        const colorInput = screen.getByLabelText(/button color/i)

        await userEvent.clear(colorInput)
        await userEvent.type(colorInput, newColor)

        expect(buttonsChanged).toHaveBeenCalledWith([
          createButton(1, {text: 'Button 1', primaryColor: newColor}),
          createButton(2, {text: 'Button 2'}),
        ])
      })

      it('updates button text color', async () => {
        const buttonsChanged = vi.fn()
        const newColor = '#051b53ff'
        render(
          <ButtonBlockIndividualButtonSettings
            {...defaultProps}
            onButtonsChange={buttonsChanged}
          />,
        )
        clickToggleButton(1)

        const colorInput = screen.getByLabelText(/text color/i)

        await userEvent.clear(colorInput)
        await userEvent.type(colorInput, newColor)

        expect(buttonsChanged).toHaveBeenCalledWith([
          createButton(1, {text: 'Button 1', secondaryColor: newColor}),
          createButton(2, {text: 'Button 2'}),
        ])
      })
    })

    describe('button style', () => {
      const renderStyleTest = (onButtonsChange = vi.fn()) => {
        const propsWithStyles = {
          ...defaultProps,
          initialButtons: [
            createButton(1, {text: 'Button 1', style: 'filled'}),
            createButton(2, {text: 'Button 2', style: 'outlined'}),
          ],
          onButtonsChange,
        }
        render(<ButtonBlockIndividualButtonSettings {...propsWithStyles} />)
        return onButtonsChange
      }

      it('updates button style to outlined', () => {
        const buttonsChanged = renderStyleTest()
        clickToggleButton(1)

        fireEvent.click(screen.getByTestId('select-button-style-dropdown'))
        fireEvent.click(screen.getByText('Outlined'))

        expect(buttonsChanged).toHaveBeenCalledWith([
          createButton(1, {text: 'Button 1', style: 'outlined'}),
          createButton(2, {text: 'Button 2', style: 'outlined'}),
        ])
      })

      it('button color picker is shown, when style is outlined', () => {
        renderStyleTest()
        clickToggleButton(2)

        expect(screen.getByLabelText(/button color/i)).toBeInTheDocument()
      })

      it('updates button style to filled', () => {
        const buttonsChanged = renderStyleTest()
        clickToggleButton(2)

        fireEvent.click(screen.getByTestId('select-button-style-dropdown'))
        fireEvent.click(screen.getByText('Filled'))

        expect(buttonsChanged).toHaveBeenCalledWith([
          createButton(1, {text: 'Button 1', style: 'filled'}),
          createButton(2, {text: 'Button 2', style: 'filled'}),
        ])
      })

      it('both color picker is visible, when style is filled', () => {
        renderStyleTest()
        clickToggleButton(1)

        expect(screen.getByLabelText(/button color/i)).toBeInTheDocument()
        expect(screen.getByLabelText(/text color/i)).toBeInTheDocument()
      })
    })

    it('updates button url', () => {
      const buttonsChanged = vi.fn()
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
      const buttonsChanged = vi.fn()
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
