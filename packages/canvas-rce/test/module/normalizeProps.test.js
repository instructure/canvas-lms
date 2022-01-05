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

import assert from 'assert'
import sinon from 'sinon'
import normalizeProps from '../../src/rce/normalizeProps'

describe('Rce normalizeProps', () => {
  let props
  const tinymce = {}
  beforeEach(() => {
    props = {editorOptions: sinon.stub().returns({})}
  })

  it('calls editorOptions with provided tinymce', () => {
    normalizeProps(props, tinymce)
    assert.ok(props.editorOptions.calledWith(tinymce))
  })

  it('sets tinymce as provided, even over prop', () => {
    const otherMCE = {}
    const normalized = normalizeProps({...props, tinymce: otherMCE}, tinymce)
    assert.equal(normalized.tinymce, tinymce)
  })

  it('retains other props', () => {
    const normalized = normalizeProps({...props, textareaId: 'textareaId'}, tinymce)
    assert.equal(normalized.textareaId, 'textareaId')
  })
})
