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

class MockMutationObserver {
  observer() {}
}

describe('Rce normalizeProps', () => {
  let props,
    tinymce = {}
  beforeEach(() => {
    props = {editorOptions: sinon.stub().returns({})}
  })

  it('calls editorOptions with provided tinymce', () => {
    normalizeProps(props, tinymce, MockMutationObserver)
    assert.ok(props.editorOptions.calledWith(tinymce))
  })

  it('sets tinymce as provided, even over prop', () => {
    const otherMCE = {}
    const normalized = normalizeProps({...props, tinymce: otherMCE}, tinymce, MockMutationObserver)
    assert.equal(normalized.tinymce, tinymce)
  })

  it('normalizes the language', () => {
    const normalized = normalizeProps({...props, language: 'mi-NZ'}, tinymce, MockMutationObserver)
    assert.equal(normalized.language, 'mi')
  })

  it('retains other props', () => {
    const normalized = normalizeProps(
      {...props, textareaId: 'textareaId'},
      tinymce,
      MockMutationObserver
    )
    assert.equal(normalized.textareaId, 'textareaId')
  })

  describe('configureMenus', () => {
    it('places instructure_media in menubar if not instRecordDisabled', () => {
      props = {...props, instRecordDisabled: false}
      const normalized = normalizeProps(props, tinymce, MockMutationObserver)
      assert.strictEqual(normalized.editorOptions.menubar, 'edit view insert format tools table')
      assert.strictEqual(
        normalized.editorOptions.menu.insert.items,
        'instructure_links instructure_image instructure_media instructure_document | instructure_equation inserttable instructure_media_embed | hr'
      )
    })

    it('instructure_media not in menubar if instRecordDisabled is set', () => {
      props = {...props, instRecordDisabled: true}
      const normalized = normalizeProps(props, tinymce, MockMutationObserver)
      assert.strictEqual(normalized.editorOptions.menubar, 'edit view insert format tools table')
      assert.strictEqual(
        normalized.editorOptions.menu.insert.items,
        'instructure_links instructure_image instructure_document | instructure_equation inserttable instructure_media_embed | hr'
      )
    })
  })
})
