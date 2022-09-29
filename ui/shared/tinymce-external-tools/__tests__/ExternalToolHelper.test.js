/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import helpers from '../ExternalToolsHelper'

describe('buttonConfig()', () => {
  let button, editor

  const subject = () => helpers.buttonConfig(button, editor)

  beforeEach(() => {
    button = {
      name: 'Name',
      id: 'ID-123',
      description: 'A nifty tool',
      favorite: true,
      canvas_icon_class: 'custom-class',
      icon_url: 'https://canvas.instructure.com/image',
    }

    editor = {
      execCommand: jest.fn(),
      $: jest.fn(),
      editorContainer: {querySelector: jest.fn()},
    }
  })

  it('does not set the custom icon class', () => {
    expect(subject().icon).toBeUndefined()
  })

  it('uses the icon url', () => {
    expect(subject().image).toEqual(button.icon_url)
  })
})
