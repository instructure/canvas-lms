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

const mockAddBlockModalOpen = vi.fn()
const mockSettingsTrayOpen = vi.fn()
const mockDeleteNode = vi.fn()
const mockDuplicateNode = vi.fn()
const mockMoveUp = vi.fn()
const mockMoveDown = vi.fn()
const mockMoveToTop = vi.fn()
const mockMoveToBottom = vi.fn()
const mockUseMoveBlock = vi.fn()
const mockUseIsEditingBlock = vi.fn()

vi.mock('../../../../store', async () => ({
  ...(await vi.importActual('../../../../store')),
  useAppSetStore: vi.fn().mockReturnValue(vi.fn()),
}))
const mockUseBlockTitle = vi.fn()

vi.mock('../../../../hooks/useBlockTitle', () => ({
  useBlockTitle: () => mockUseBlockTitle(),
}))

const getUseBlockTitleMock = (title: string) => title

vi.mock('../../../../hooks/useAddBlockModal', () => ({
  useAddBlockModal: () => ({
    open: mockAddBlockModalOpen,
    close: vi.fn(),
  }),
}))

vi.mock('../../../../hooks/useSettingsTray', () => ({
  useSettingsTray: () => ({
    open: mockSettingsTrayOpen,
    close: vi.fn(),
  }),
}))

vi.mock('../../../../hooks/useIsEditingBlock', () => ({
  useIsEditingBlock: () => mockUseIsEditingBlock(),
}))

const getUseIsEditingBlockMock = ({
  isEditing,
  isEditingViaEditButton,
}: {
  isEditing: boolean
  isEditingViaEditButton: boolean
}) => ({
  isEditing,
  isEditingViaEditButton,
})

vi.mock('../../../../hooks/useDeleteNode', () => ({
  useDeleteNode: () => mockDeleteNode,
}))

vi.mock('../../../../hooks/useDuplicateNode', () => ({
  useDuplicateNode: () => mockDuplicateNode,
}))

vi.mock('../../../../hooks/useMoveBlock', () => ({
  useMoveBlock: () => mockUseMoveBlock(),
}))

const getMoveBlockMock = ({
  canMoveUp,
  canMoveDown,
}: {
  canMoveUp: boolean
  canMoveDown: boolean
}) => ({
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
    ...props,
  })

  beforeEach(() => {
    vi.clearAllMocks()
    mockUseIsEditingBlock.mockReturnValue(
      getUseIsEditingBlockMock({isEditing: false, isEditingViaEditButton: false}),
    )
    mockUseMoveBlock.mockReturnValue(
      getMoveBlockMock({
        canMoveUp: true,
        canMoveDown: true,
      }),
    )
    mockUseBlockTitle.mockReturnValue(getUseBlockTitleMock('Test Block Title'))
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

      expect(mockAddBlockModalOpen).toHaveBeenCalledWith(expect.any(String))
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
      const editButton = component.getByTestId('edit-block-settings-button')

      fireEvent.click(editButton)

      expect(mockSettingsTrayOpen).toHaveBeenCalledWith(expect.any(String))
    })

    describe('Move button', () => {
      it('opens reorder menu when clicked', () => {
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const moveButton = component.getByTestId('move-block-button')

        fireEvent.click(moveButton)

        expect(component.getByText(/move up: test block title/i)).toBeInTheDocument()
        expect(component.getByText(/move down: test block title/i)).toBeInTheDocument()
        expect(component.getByText(/move to top: test block title/i)).toBeInTheDocument()
        expect(component.getByText(/move to bottom: test block title/i)).toBeInTheDocument()
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

        expect(component.getByText(/move up: test block title/i)).toBeInTheDocument()
        expect(component.getByText(/move to top: test block title/i)).toBeInTheDocument()
        expect(component.queryByText(/move down: test block title/i)).not.toBeInTheDocument()
        expect(component.queryByText(/move to bottom: test block title/i)).not.toBeInTheDocument()
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

        expect(component.queryByText(/move up: test block title/i)).not.toBeInTheDocument()
        expect(component.queryByText(/move to top: test block title/i)).not.toBeInTheDocument()
        expect(component.getByText(/move down: test block title/i)).toBeInTheDocument()
        expect(component.getByText(/move to bottom: test block title/i)).toBeInTheDocument()
      })

      it.each([
        ['Move Up', /move up: test block title/i, mockMoveUp],
        ['Move Down', /move down: test block title/i, mockMoveDown],
        ['Move to Top', /move to top: test block title/i, mockMoveToTop],
        ['Move to Bottom', /move to bottom: test block title/i, mockMoveToBottom],
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

  describe('A11yEditButton', () => {
    it('is rendered when block is not in edit mode', () => {
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const editButton = component.getByTestId('a11y-edit-button')

      expect(editButton).toBeInTheDocument()
    })

    it('is not rendered when block is in edit mode', () => {
      mockUseIsEditingBlock.mockReturnValue(
        getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: true}),
      )
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const editButton = component.queryByTestId('a11y-edit-button')

      expect(editButton).not.toBeInTheDocument()
    })

    it('renders with block title as an aria-label', () => {
      const component = renderBlock(BaseBlockEditWrapper, {
        ...getDefaultProps(),
      })
      const editButton = component.getByTestId('a11y-edit-button')

      expect(editButton).toHaveAttribute(
        'aria-label',
        `Edit content for ${getDefaultProps().title}`,
      )
    })

    it('renders with custom title as an aria-label', () => {
      const customTitle = 'Custom Title'
      mockUseBlockTitle.mockReturnValue(getUseBlockTitleMock(customTitle))

      const component = renderBlock(BaseBlockEditWrapper, {
        ...getDefaultProps(),
      })
      const editButton = component.getByTestId('a11y-edit-button')
      expect(editButton).toHaveAttribute('aria-label', `Edit content for ${customTitle}`)
    })
  })

  describe('A11yDoneEditingButton', () => {
    it('renders twice when block is in edit mode', () => {
      mockUseIsEditingBlock.mockReturnValue(
        getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: true}),
      )
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

      expect(doneButtons).toHaveLength(2)
    })

    it('not renders twice when block is not in edit mode', () => {
      const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
      const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

      expect(doneButtons).toHaveLength(0)
    })

    describe('Focus behavior', () => {
      it('renders 1st Done editing button only focusable when edited via edit button', () => {
        mockUseIsEditingBlock.mockReturnValue(
          getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: true}),
        )
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

        expect(doneButtons[0]).toHaveAttribute('data-focus-reveal-button', 'true')
      })

      it('renders 1st Done editing button only focusable when not edited via edit button', () => {
        mockUseIsEditingBlock.mockReturnValue(
          getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: false}),
        )
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

        expect(doneButtons[0]).toHaveAttribute('data-focus-reveal-button', 'true')
      })

      it('renders 2nd Done editing button visible when edited via edit button', () => {
        mockUseIsEditingBlock.mockReturnValue(
          getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: true}),
        )
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

        expect(doneButtons[1]).not.toHaveAttribute('data-focus-reveal-button')
      })

      it('renders 2nd Done editing button only focusable when not edited via edit button', () => {
        mockUseIsEditingBlock.mockReturnValue(
          getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: false}),
        )
        const component = renderBlock(BaseBlockEditWrapper, getDefaultProps())
        const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

        expect(doneButtons[1]).toHaveAttribute('data-focus-reveal-button', 'true')
      })
    })

    it('renders both buttons with block title in aria-label', () => {
      mockUseIsEditingBlock.mockReturnValue(
        getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: true}),
      )
      const component = renderBlock(BaseBlockEditWrapper, {
        ...getDefaultProps(),
      })
      const expectedAriaLabel = `Done editing for ${getDefaultProps().title}`
      const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

      expect(doneButtons[0]).toHaveAttribute('aria-label', expectedAriaLabel)
      expect(doneButtons[1]).toHaveAttribute('aria-label', expectedAriaLabel)
    })

    it('renders both buttons with custom title in aria-label', () => {
      mockUseIsEditingBlock.mockReturnValue(
        getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: true}),
      )
      const customTitle = 'Custom Title'
      mockUseBlockTitle.mockReturnValue(getUseBlockTitleMock(customTitle))

      const component = renderBlock(BaseBlockEditWrapper, {
        ...getDefaultProps(),
      })
      const expectedAriaLabel = `Done editing for ${customTitle}`
      const doneButtons = component.queryAllByTestId('a11y-done-editing-button')

      expect(doneButtons[0]).toHaveAttribute('aria-label', expectedAriaLabel)
      expect(doneButtons[1]).toHaveAttribute('aria-label', expectedAriaLabel)
    })
  })
})
