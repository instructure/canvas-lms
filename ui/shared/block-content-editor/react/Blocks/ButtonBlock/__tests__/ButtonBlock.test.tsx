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

import {screen} from '@testing-library/react'
import {ButtonBlock} from '../ButtonBlock'
import {ButtonBlockProps} from '../types'
import {renderBlock} from '../../__tests__/render-helper'

const useIsInEditorMock = vi.fn()
vi.mock('../../../hooks/useIsInEditor', () => ({
  useIsInEditor: () => useIsInEditorMock(),
}))

const useIsEditingBlockMock = vi.fn()
vi.mock('../../../hooks/useIsEditingBlock', () => ({
  useIsEditingBlock: () => useIsEditingBlockMock(),
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

const defaultProps: ButtonBlockProps = {
  includeBlockTitle: false,
  alignment: 'left',
  layout: 'horizontal',
  isFullWidth: false,
  buttons: [
    {
      id: 1,
      text: '',
      url: '',
      linkOpenMode: 'new-tab',
      primaryColor: '#000000',
      secondaryColor: '#FFFFFF',
      style: 'filled',
    },
  ],
  backgroundColor: '#FF0000',
  titleColor: '#000000',
  title: '',
}

describe('ButtonBlock', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  // Skipped: useIsEditingBlock hook returning undefined - ARC-9214
  it('renders ButtonBlockEdit in edit mode', () => {
    useIsInEditorMock.mockReturnValue(true)
    useIsEditingBlockMock.mockReturnValue(
      getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: false}),
    )
    renderBlock(ButtonBlock, defaultProps)
    expect(screen.getByTestId('button-block-edit')).toBeInTheDocument()
  })

  // Skipped: useIsEditingBlock hook returning undefined - ARC-9214
  it('renders ButtonBlockEditPreview in editPreview mode', () => {
    useIsInEditorMock.mockReturnValue(true)
    useIsEditingBlockMock.mockReturnValue(
      getUseIsEditingBlockMock({isEditing: false, isEditingViaEditButton: false}),
    )
    renderBlock(ButtonBlock, defaultProps)
    expect(screen.getByTestId('button-block-edit-preview')).toBeInTheDocument()
  })

  // Skipped: useIsEditingBlock hook returning undefined - ARC-9214
  it('renders ButtonBlockView in view mode', () => {
    useIsInEditorMock.mockReturnValue(false)
    renderBlock(ButtonBlock, defaultProps)
    expect(screen.getByTestId('button-block-view')).toBeInTheDocument()
  })
})
