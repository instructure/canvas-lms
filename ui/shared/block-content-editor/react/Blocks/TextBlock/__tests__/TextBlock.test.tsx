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

import {TextBlock} from '../TextBlock'
import {renderBlock} from '../../__tests__/render-helper'
import {mockBlockContentEditorContext} from '../../../__tests__/mockBlockContentEditorContext'
import {TextBlockProps} from '../types'

jest.mock('../../../BlockContentEditorContext', () => ({
  __esModule: true,
  useBlockContentEditorContext: jest.fn(() => mockBlockContentEditorContext({})),
}))

const defaultProps: TextBlockProps = {
  title: 'Test Title',
  includeBlockTitle: true,
  backgroundColor: '#ff0000',
  titleColor: '#00ff00',
  content: '',
}

describe('TextBlock', () => {
  it('should render without crashing', () => {
    renderBlock(TextBlock, defaultProps)
    expect(true).toBe(true)
  })
})
