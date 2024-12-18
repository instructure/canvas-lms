/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import normalizeProps from '../../src/rce/normalizeProps'

describe('Rce normalizeProps', () => {
  let props
  const tinymce = {}
  let mockEditorOptions
  beforeEach(() => {
    mockEditorOptions = jest.fn(() => {
      return {}
    })
    props = {editorOptions: mockEditorOptions}
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('calls editorOptions with provided tinymce', () => {
    normalizeProps(props, tinymce)
    expect(mockEditorOptions).toHaveBeenCalled()
  })

  it('sets tinymce as provided, even over prop', () => {
    const otherMCE = {}
    const normalized = normalizeProps({...props, tinymce: otherMCE}, tinymce)
    expect(normalized.tinymce).toEqual(tinymce)
  })

  it('retains other props', () => {
    const normalized = normalizeProps({...props, textareaId: 'textareaId'}, tinymce)
    expect(normalized.textareaId).toEqual('textareaId')
  })
})
