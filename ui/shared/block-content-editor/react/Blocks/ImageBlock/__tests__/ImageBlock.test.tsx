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

import {ImageBlock} from '../ImageBlock'
import {renderBlock} from '../../__tests__/render-helper'

vi.mock('../../../BlockContentEditorContext', () => ({
  __esModule: true,
}))

describe('ImageBlock', () => {
  it('should render without crashing', () => {
    renderBlock(ImageBlock, {
      title: '',
      includeBlockTitle: false,
      backgroundColor: 'color',
      titleColor: 'color',
      url: 'https://example.com/image.jpg',
      altText: 'Example Image',
      caption: 'This is an example image.',
      altTextAsCaption: false,
      decorativeImage: false,
    })
    expect(true).toBe(true)
  })
})
