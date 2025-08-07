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

import {render} from '@testing-library/react'
import {ButtonBlockSettings} from '../ButtonBlockSettings'

const mockSetProp = jest.fn()
const mockUseNode = jest.fn()

jest.mock('@craftjs/core', () => ({
  useNode: (selector: any) => mockUseNode(selector),
}))

const mockIndividualButtonSettings = jest.fn()
jest.mock('../ButtonBlockIndividualButtonSettings', () => ({
  ButtonBlockIndividualButtonSettings: (props: any) => mockIndividualButtonSettings(props),
}))

const mockGeneralButtonSettings = jest.fn()
jest.mock('../ButtonBlockGeneralButtonSettings', () => ({
  ButtonBlockGeneralButtonSettings: (props: any) => mockGeneralButtonSettings(props),
}))

const defaultButtons = [{id: 1}, {id: 2}]
const defaultAlignment = 'left'
const defaultLayout = 'horizontal'
const defaultIsFullWidth = false

describe('ButtonBlockSettings', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockUseNode.mockReturnValue({
      actions: {setProp: mockSetProp},
      buttons: defaultButtons,
      alignment: defaultAlignment,
      layout: defaultLayout,
      isFullWidth: defaultIsFullWidth,
    })
  })

  const assertSetPropCallback = (
    expectedProperty: 'buttons' | 'alignment' | 'layout' | 'isFullWidth',
    expectedValue: any,
  ) => {
    expect(mockSetProp).toHaveBeenCalledTimes(1)

    const setPropCallback = mockSetProp.mock.calls[0][0]
    const mockProps = {
      settings: {
        alignment: defaultAlignment,
        layout: defaultLayout,
        isFullWidth: defaultIsFullWidth,
        buttons: defaultButtons,
      },
    }
    setPropCallback(mockProps)
    expect(mockProps.settings[expectedProperty]).toEqual(expectedValue)
  }

  describe('Individual button settings', () => {
    it('passes correct props', () => {
      render(<ButtonBlockSettings />)
      expect(mockIndividualButtonSettings).toHaveBeenCalledWith({
        initialButtons: defaultButtons,
        onButtonsChange: expect.any(Function),
      })
    })

    it('calls setProp when buttons change', () => {
      render(<ButtonBlockSettings />)
      const {onButtonsChange} = mockIndividualButtonSettings.mock.calls[0][0]
      const newButtons = [{id: 11}, {id: 12}, {id: 13}]
      onButtonsChange(newButtons)
      assertSetPropCallback('buttons', newButtons)
    })
  })

  describe('General button settings', () => {
    it('passes correct props', () => {
      render(<ButtonBlockSettings />)
      expect(mockGeneralButtonSettings).toHaveBeenCalledWith({
        alignment: defaultAlignment,
        layout: defaultLayout,
        isFullWidth: defaultIsFullWidth,
        onAlignmentChange: expect.any(Function),
        onLayoutChange: expect.any(Function),
        onIsFullWidthChange: expect.any(Function),
      })
    })

    it('calls setProp when alignment changes', () => {
      render(<ButtonBlockSettings />)
      const {onAlignmentChange} = mockGeneralButtonSettings.mock.calls[0][0]
      const newAlignment = 'center'
      onAlignmentChange(newAlignment)
      assertSetPropCallback('alignment', newAlignment)
    })

    it('calls setProp when layout changes', () => {
      render(<ButtonBlockSettings />)
      const {onLayoutChange} = mockGeneralButtonSettings.mock.calls[0][0]
      const newLayout = 'vertical'
      onLayoutChange(newLayout)
      assertSetPropCallback('layout', newLayout)
    })

    it('calls setProp when isFullWidth changes', () => {
      render(<ButtonBlockSettings />)
      const {onIsFullWidthChange} = mockGeneralButtonSettings.mock.calls[0][0]
      const newIsFullWidth = true
      onIsFullWidthChange(newIsFullWidth)
      assertSetPropCallback('isFullWidth', newIsFullWidth)
    })
  })
})
