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

import {renderBlock} from '../../__tests__/render-helper'
import {ImageTextBlock} from '../ImageTextBlock'
import {ImageTextBlockProps} from '../types'

jest.mock('../../../store', () => ({
  __esModule: true,
  ...jest.requireActual('../../../store'),
  useAppSetStore: jest.fn().mockReturnValue(jest.fn()),
}))

const useIsInEditorMock = jest.fn()
jest.mock('../../../hooks/useIsInEditor', () => ({
  useIsInEditor: () => useIsInEditorMock(),
}))

const useIsEditingBlockMock = jest.fn()
jest.mock('../../../hooks/useIsEditingBlock', () => ({
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

const defaultProps: ImageTextBlockProps = {
  title: '',
  content: '',
  url: '',
  altText: '',
  includeBlockTitle: false,
  backgroundColor: '',
  titleColor: '',
  arrangement: 'left',
  textToImageRatio: '1:1',
  fileName: '',
  altTextAsCaption: false,
  decorativeImage: false,
  caption: '',
}

describe('ImageTextBlock', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('when block in edit mode', () => {
    beforeEach(() => {
      useIsInEditorMock.mockReturnValue(true)
      useIsEditingBlockMock.mockReturnValue(
        getUseIsEditingBlockMock({isEditing: true, isEditingViaEditButton: false}),
      )
    })

    it('does render in edit mode', () => {
      const component = renderBlock(ImageTextBlock, defaultProps)
      expect(component.getByTestId('imagetext-block-edit')).toBeInTheDocument()
    })
  })

  describe('when block in preview mode', () => {
    beforeEach(() => {
      useIsInEditorMock.mockReturnValue(true)
      useIsEditingBlockMock.mockReturnValue(
        getUseIsEditingBlockMock({isEditing: false, isEditingViaEditButton: false}),
      )
    })

    it('does render in preview mode', () => {
      const component = renderBlock(ImageTextBlock, defaultProps)
      expect(component.getByTestId('imagetext-block-editpreview')).toBeInTheDocument()
    })
  })

  describe('when block in view mode', () => {
    beforeEach(() => {
      useIsInEditorMock.mockReturnValue(false)
    })

    it('does render in view mode', () => {
      const component = renderBlock(ImageTextBlock, defaultProps)
      expect(component.getByTestId('imagetext-block-view')).toBeInTheDocument()
    })
  })
})
