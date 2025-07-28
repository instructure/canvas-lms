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

jest.mock('../../../BlockContentEditorContext', () => ({
  __esModule: true,
  useBlockContentEditorContext: jest.fn(() => ({})),
}))

describe('TextBlock', () => {
  it('should render without crashing', () => {
    renderBlock(TextBlock, {title: 'Test Title', content: 'Test Content'})
    expect(true).toBe(true)
  })
})
