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
import {fireEvent} from '@testing-library/react'
import {BaseBlockEditWrapper} from '../BaseBlockEditWrapper'
import {renderBlock} from '../../../__tests__/render-helper'
const {any} = expect

const mockAddBlockModalOpen = jest.fn()
const mockSettingsTrayOpen = jest.fn()
const mockDeleteNode = jest.fn()
const mockDuplicateNode = jest.fn()
const mockMoveUp = jest.fn()
const mockMoveDown = jest.fn()
const mockMoveToTop = jest.fn()
const mockMoveToBottom = jest.fn()
const mockUseMoveBlock = jest.fn()

jest.mock('../../../../BlockContentEditorContext', () => ({
  useBlockContentEditorContext: () => ({
    addBlockModal: {open: mockAddBlockModalOpen},
    settingsTray: {open: mockSettingsTrayOpen},
    initialAddBlockHandler: jest.fn(),
    editor: jest.fn(),
  }),
}))

jest.mock('../../../../hooks/useDeleteNode', () => ({
  useDeleteNode: () => mockDeleteNode,
}))

jest.mock('../../../../hooks/useDuplicateNode', () => ({
  useDuplicateNode: () => mockDuplicateNode,
}))

jest.mock('../../../../hooks/useMoveBlock', () => ({
  useMoveBlock: () => mockUseMoveBlock(),
}))

const getMoveBlockMock = ({
  canMoveUp,
  canMoveDown,
}: {canMoveUp: boolean; canMoveDown: boolean}) => ({
  canMoveUp,
  canMoveDown,
  moveUp: mockMoveUp,
  moveDown: mockMoveDown,
  moveToTop: mockMoveToTop,
  moveToBottom: mockMoveToBottom,
})

describe('BaseBlockEditWrapper', () => {
  const getDefaultProps = (props: object = {}) => ({
    title: 'Test Block Title',
    setIsEditMode: jest.fn(),
    isEditMode: false,
    ...props,
  })

  beforeEach(() => {
    jest.clearAllMocks()
    mockUseMoveBlock.mockReturnValue(
      getMoveBlockMock({
        canMoveUp: true,
        canMoveDown: true,
      }),
    )
  })

  it('renders the title', () => {
    const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
    expect(component.getByText('Test Block Title')).toBeInTheDocument()
  })

  it('renders children components', () => {
    const children = <div data-testid="test-child">Test Child Content</div>
    const component = renderBlock(BaseBlockEditWrapper, {
      ...getDefaultProps(),
      children,
    })
    expect(component.getByTestId('test-child')).toBeInTheDocument()
  })

  describe('Background color', () => {
    it('applies white background color by default', () => {
      const defaultColor = 'rgb(255, 255, 255)'
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const backgroundElement = component.getByTestId('background-color-applier')
      expect(backgroundElement).toHaveStyle({'background-color': defaultColor})
    })

    it('applies custom background color when provided', () => {
      const customColor = 'rgb(255, 0, 0)'
      const component = renderBlock(BaseBlockEditWrapper, {
        ...getDefaultProps(),
        backgroundColor: customColor,
      })
      const backgroundElement = component.getByTestId('background-color-applier')
      expect(backgroundElement).toHaveStyle({'background-color': customColor})
    })
  })

  describe('Insert button', () => {
    it('opens Add Block modal when Insert button is clicked', () => {
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const insertButton = component.getByText(/add/i)

      fireEvent.click(insertButton)

      expect(mockAddBlockModalOpen).toHaveBeenCalledWith(any(String))
    })
  })

  describe('Menu buttons', () => {
    it('deletes the block when Remove button is clicked', () => {
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const removeButton = component.getByText(/remove/i)

      fireEvent.click(removeButton)

      expect(mockDeleteNode).toHaveBeenCalled()
    })

    it('duplicates the block when Duplicate button is clicked', () => {
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const duplicateButton = component.getByText(/duplicate/i)

      fireEvent.click(duplicateButton)

      expect(mockDuplicateNode).toHaveBeenCalled()
    })

    it('opens Settings Tray when Edit button is clicked', () => {
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const editButton = component.getByText(/edit/i)

      fireEvent.click(editButton)

      expect(mockSettingsTrayOpen).toHaveBeenCalledWith(any(String))
    })

    describe('Move button', () => {
      it('opens reorder menu when clicked', () => {
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const moveButton = component.getByTestId('move-block-button')

        fireEvent.click(moveButton)

        expect(component.getByText(/move up/i)).toBeInTheDocument()
        expect(component.getByText(/move down/i)).toBeInTheDocument()
        expect(component.getByText(/move to top/i)).toBeInTheDocument()
        expect(component.getByText(/move to bottom/i)).toBeInTheDocument()
      })

      it('does not render when moving is not possible', () => {
        mockUseMoveBlock.mockReturnValue(
          getMoveBlockMock({
            canMoveUp: false,
            canMoveDown: false,
          }),
        )
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())

        expect(component.queryByTestId('move-block-button')).not.toBeInTheDocument()
      })

      it('only shows move up options when moving down is not possible', () => {
        mockUseMoveBlock.mockReturnValue(
          getMoveBlockMock({
            canMoveUp: true,
            canMoveDown: false,
          }),
        )
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const moveButton = component.getByTestId('move-block-button')

        fireEvent.click(moveButton)

        expect(component.getByText(/move up/i)).toBeInTheDocument()
        expect(component.getByText(/move to top/i)).toBeInTheDocument()
        expect(component.queryByText(/move down/i)).not.toBeInTheDocument()
        expect(component.queryByText(/move to bottom/i)).not.toBeInTheDocument()
      })

      it('only shows move down options when moving up is not possible', () => {
        mockUseMoveBlock.mockReturnValue(
          getMoveBlockMock({
            canMoveUp: false,
            canMoveDown: true,
          }),
        )
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const moveButton = component.getByTestId('move-block-button')

        fireEvent.click(moveButton)

        expect(component.queryByText(/move up/i)).not.toBeInTheDocument()
        expect(component.queryByText(/move to top/i)).not.toBeInTheDocument()
        expect(component.getByText(/move down/i)).toBeInTheDocument()
        expect(component.getByText(/move to bottom/i)).toBeInTheDocument()
      })

      it.each([
        ['Move Up', /move up/i, mockMoveUp],
        ['Move Down', /move down/i, mockMoveDown],
        ['Move to Top', /move to top/i, mockMoveToTop],
        ['Move to Bottom', /move to bottom/i, mockMoveToBottom],
      ])('moves block when %s menu item is clicked', (_name, matcher, mockFunction) => {
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const moveButton = component.getByTestId('move-block-button')

        fireEvent.click(moveButton)

        const menuItem = component.getByText(matcher)
        fireEvent.click(menuItem)

        expect(mockFunction).toHaveBeenCalled()
      })
    })
  })
})
