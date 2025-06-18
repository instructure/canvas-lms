/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'

jest.mock('@canvas/rce/RichContentEditor', () => ({
  loadNewEditor: (textarea, _options, callback) => {
    textarea.addClass('tinymce-active')
    callback?.()
  },
}))

describe('ValidatedMixin', () => {
  it('can find tinymce instances as fields', () => {
    document.body.innerHTML = `
      <div>
        <textarea name="message" data-rich_text="true"></textarea>
        <div class="mce-tinymce"></div>
      </div>
    `

    const ValidatedMixin = {
      $: selector => $(selector),
      findSiblingTinymce: $el => $el.siblings('.mce-tinymce'),
      findField(field, useGlobalSelector = false) {
        let $el
        const selector = `[name='${field}']`
        if (useGlobalSelector) {
          $el = $(selector)
        } else {
          $el = this.$(selector)
        }
        if ($el.data('rich_text')) {
          $el = this.findSiblingTinymce($el)
        }
        return $el
      },
    }

    const element = ValidatedMixin.findField('message')
    expect(element).toHaveLength(1)
  })
})
