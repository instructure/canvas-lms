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

import {render, screen, fireEvent} from '@testing-library/react'
import {ButtonBlockSettings} from '../ButtonBlockSettings'

const mockSetProp = jest.fn()
const mockUseNode = jest.fn()

jest.mock('@craftjs/core', () => ({
  useNode: (selector: any) => mockUseNode(selector),
}))

jest.mock('../ButtonBlockIndividualButtonSettings', () => ({
  ButtonBlockIndividualButtonSettings: ({initialButtons, onButtonsChange}: any) => (
    <div data-testid="button-block-individual-settings">
      {initialButtons.map((button: any) => (
        <div key={button.id}>Button-{button.id}</div>
      ))}
      <button
        onClick={() => {
          onButtonsChange([{id: 11}, {id: 12}, {id: 13}])
        }}
      >
        Change buttons
      </button>
    </div>
  ),
}))

describe('ButtonBlockSettings', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockUseNode.mockReturnValue({
      actions: {setProp: mockSetProp},
      buttons: [{id: 1}, {id: 2}],
    })
  })

  const assertSetPropCallback = (expectedProperty: 'buttons', expectedValue: any) => {
    expect(mockSetProp).toHaveBeenCalledTimes(1)

    const setPropCallback = mockSetProp.mock.calls[0][0]
    const mockProps = {
      settings: {buttons: [{id: 1}]},
    }
    setPropCallback(mockProps)
    expect(mockProps.settings[expectedProperty]).toEqual(expectedValue)
  }

  describe('Individual button settings', () => {
    describe('rendering', () => {
      it('renders component', () => {
        render(<ButtonBlockSettings />)
        expect(screen.getByTestId('button-block-individual-settings')).toBeInTheDocument()
      })

      it('passes button props', () => {
        render(<ButtonBlockSettings />)
        const buttons = screen.getAllByText(/Button-\d+/)
        expect(buttons).toHaveLength(2)
        expect(buttons[0]).toHaveTextContent('Button-1')
        expect(buttons[1]).toHaveTextContent('Button-2')
      })
    })

    describe('event handlers', () => {
      it('calls setProp when buttons change', () => {
        render(<ButtonBlockSettings />)
        fireEvent.click(screen.getByText('Change buttons'))
        assertSetPropCallback('buttons', [{id: 11}, {id: 12}, {id: 13}])
      })
    })
  })
})
