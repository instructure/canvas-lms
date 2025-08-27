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

jest.mock('../../../BlockContentEditorContext', () => ({
  __esModule: true,
  useBlockContentEditorContext: jest.fn(() => ({})),
}))

const useGetRenderModeMock = jest.fn()
jest.mock('../../BaseBlock/useGetRenderMode', () => ({
  useGetRenderMode: () => useGetRenderModeMock(),
}))

const defaultProps: ButtonBlockProps = {
  settings: {
    includeBlockTitle: false,
    alignment: 'left',
    layout: 'horizontal',
    isFullWidth: false,
    buttons: [{id: 1, text: ''}],
    backgroundColor: '#FF0000',
  },
  title: '',
}

describe('ButtonBlock', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders ButtonBlockEdit in edit mode', () => {
    useGetRenderModeMock.mockReturnValue({isEditMode: true})
    renderBlock(ButtonBlock, defaultProps)
    expect(screen.getByTestId('button-block-edit')).toBeInTheDocument()
  })

  it('renders ButtonBlockEditPreview in editPreview mode', () => {
    useGetRenderModeMock.mockReturnValue({isEditPreviewMode: true})
    renderBlock(ButtonBlock, defaultProps)
    expect(screen.getByTestId('button-block-edit-preview')).toBeInTheDocument()
  })

  it('renders ButtonBlockView in view mode', () => {
    useGetRenderModeMock.mockReturnValue({isViewMode: true})
    renderBlock(ButtonBlock, defaultProps)
    expect(screen.getByTestId('button-block-view')).toBeInTheDocument()
  })
})
