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

jest.mock('../../../BlockContentEditorContext', () => ({
  __esModule: true,
  useBlockContentEditorContext: jest.fn(() => ({})),
}))

const useGetRenderModeMock = jest.fn()
jest.mock('../../BaseBlock/useGetRenderMode', () => ({
  useGetRenderMode: () => useGetRenderModeMock(),
}))

const defaultProps: ImageTextBlockProps = {
  title: '',
  content: '',
  url: '',
  altText: '',
  settings: {
    includeBlockTitle: false,
  },
}

describe('ImageTextBlock', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('when block in edit mode', () => {
    beforeEach(() => {
      useGetRenderModeMock.mockReturnValue({isEditMode: true})
    })

    it('does render in edit mode', () => {
      const component = renderBlock(ImageTextBlock, defaultProps)
      expect(component.getByTestId('imagetext-block-edit')).toBeInTheDocument()
    })
  })
})
